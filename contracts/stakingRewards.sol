// FILE: src/stakingRewards.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StakingRewards is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Roles ---
    bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");
    bytes32 public constant RATE_SETTER_ROLE = keccak256("RATE_SETTER_ROLE");

    // --- Immutable Configuration ---
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    address public immutable feeRecipient;
    uint256 public immutable rewardEndTime;

    // --- Constants ---
    uint256 public constant UNSTAKING_FEE_BP = 200; // 2% Fee
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant LOCKUP_PERIOD = 7 days;
    uint256 public constant REWARD_DURATION = 3 * 365 days;

    // --- Reward State ---
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // --- Staking State ---
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    // --- User Reward State ---
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // --- Lockup State ---
    mapping(address => uint256) public lockupReleaseTime;

    // --- Events ---
    event RewardRateUpdated(uint256 newRate);
    event RewardsFunded(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 fee);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address stakingTokenInstance, address rewardTokenInstance, address admin, address feeRecipientAddress) {
        require(stakingTokenInstance != address(0) && rewardTokenInstance != address(0), "SR: Invalid token addresses");
        require(admin != address(0), "SR: Invalid admin address");
        require(feeRecipientAddress != address(0), "SR: Invalid fee recipient");

        stakingToken = IERC20(stakingTokenInstance);
        rewardToken = IERC20(rewardTokenInstance);
        feeRecipient = feeRecipientAddress;
        rewardEndTime = block.timestamp + REWARD_DURATION;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        lastUpdateTime = block.timestamp;
    }

    // --- Modifiers ---
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = _lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // --- Reward Logic Views ---
    function _lastTimeRewardApplicable() internal view returns (uint256) {
        return Math.min(block.timestamp, rewardEndTime);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 lastTime = _lastTimeRewardApplicable();
        if (lastTime <= lastUpdateTime) {
            return rewardPerTokenStored;
        }
        uint256 timeElapsed = lastTime - lastUpdateTime;
        uint256 precision = 1e18;
        return rewardPerTokenStored + (timeElapsed * rewardRate * precision) / totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 stakedAmount = balanceOf[account];
        uint256 precision = 1e18;
        uint256 rewardSinceLastUpdate =
            (stakedAmount * (currentRewardPerToken - userRewardPerTokenPaid[account])) / precision;
        return rewards[account] + rewardSinceLastUpdate;
    }

    // --- User Functions ---
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "SR: Cannot stake 0");

        lockupReleaseTime[msg.sender] = block.timestamp + LOCKUP_PERIOD;

        uint256 balanceBefore = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = stakingToken.balanceOf(address(this));
        uint256 actualAmountReceived = balanceAfter - balanceBefore;

        require(actualAmountReceived > 0, "SR: Staked amount resulted in 0 actual transfer");

        totalSupply += actualAmountReceived;
        balanceOf[msg.sender] += actualAmountReceived;

        emit Staked(msg.sender, actualAmountReceived);
    }

    function unstake(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(block.timestamp >= lockupReleaseTime[msg.sender], "SR: Tokens are locked");
        require(amount > 0, "SR: Cannot unstake 0");
        uint256 currentBalance = balanceOf[msg.sender];
        require(amount <= currentBalance, "SR: Amount exceeds balance");

        uint256 fee = (amount * UNSTAKING_FEE_BP) / BASIS_POINTS_DIVISOR;
        uint256 netAmount = amount - fee;

        totalSupply -= amount;
        balanceOf[msg.sender] = currentBalance - amount;

        if (fee > 0) {
            stakingToken.safeTransfer(feeRecipient, fee);
        }
        stakingToken.safeTransfer(msg.sender, netAmount);

        emit Unstaked(msg.sender, amount, fee);
    }

    function claimRewards() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "SR: No rewards to claim");

        uint256 contractRewardBalance = rewardToken.balanceOf(address(this));
        require(contractRewardBalance >= reward, "SR: Insufficient reward balance in contract");

        uint256 fee = (reward * UNSTAKING_FEE_BP) / BASIS_POINTS_DIVISOR;
        uint256 netReward = reward - fee;

        rewards[msg.sender] = 0;

        if (fee > 0) {
            rewardToken.safeTransfer(feeRecipient, fee);
        }
        rewardToken.safeTransfer(msg.sender, netReward);

        emit RewardPaid(msg.sender, netReward);
    }

    // --- Admin / Role Functions ---
    function setRewardRate(uint256 newRewardRate) external onlyRole(RATE_SETTER_ROLE) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = _lastTimeRewardApplicable();
        rewardRate = newRewardRate;
        emit RewardRateUpdated(newRewardRate);
    }

    function fundRewards(uint256 amount) external onlyRole(FUNDER_ROLE) {
        require(amount > 0, "SR: Cannot fund 0");
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsFunded(amount);
    }

    function recoverExcessRewardTokens(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp > rewardEndTime, "SR: Reward period not finished");
        require(to != address(0), "SR: Invalid recipient");
        rewardToken.safeTransfer(to, amount);
    }
}
