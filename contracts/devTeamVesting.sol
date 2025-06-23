// FILE: src/DevTeamVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract DevTeamVesting {
    using SafeERC20 for IERC20;

    // --- Immutable Vesting Parameters ---
    IERC20 public immutable xToken;
    address public immutable devBeneficiary;
    uint256 public immutable totalAmount;
    uint256 public immutable startTime;
    uint256 public immutable cliffDuration;
    uint256 public immutable vestingDuration;

    // --- Mutable State ---
    uint256 public claimedAmount;

    // --- Events ---
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    constructor(
        address token,
        address beneficiary,
        uint256 total,
        uint256 cliffDurationSeconds,
        uint256 vestingDurationSeconds
    ) {
        require(token != address(0), "DV: Invalid token address");
        require(beneficiary != address(0), "DV: Invalid beneficiary address");
        require(total > 0, "DV: Total amount must be positive");
        require(vestingDurationSeconds > 0, "DV: Vesting duration must be positive");

        xToken = IERC20(token);
        devBeneficiary = beneficiary;
        totalAmount = total;
        startTime = block.timestamp;
        cliffDuration = cliffDurationSeconds;
        vestingDuration = vestingDurationSeconds;
    }

    /**
     * @notice Calculates the amount of tokens that have vested up to the current time.
     * @return vestedSoFar The amount of tokens vested.
     */
    function vestedAmount() public view returns (uint256 vestedSoFar) {
        uint256 currentTime = block.timestamp;
        uint256 cliffEndTime = startTime + cliffDuration;

        if (currentTime < cliffEndTime) {
            return 0;
        }

        uint256 vestingEndTime = cliffEndTime + vestingDuration;

        if (currentTime >= vestingEndTime) {
            return totalAmount;
        }

        uint256 timePassedSinceCliff = currentTime - cliffEndTime;

        vestedSoFar = (totalAmount * timePassedSinceCliff) / vestingDuration;
    }

    /**
     * @notice Allows the beneficiary to claim their vested tokens.
     * @param amount The amount of tokens to claim.
     */
    function claimVestedTokens(uint256 amount) external {
        require(msg.sender == devBeneficiary, "DV: Caller is not the beneficiary");
        require(amount > 0, "DV: Cannot claim 0");

        uint256 vestedSoFar = vestedAmount();
        uint256 alreadyClaimed = claimedAmount;

        uint256 claimable = vestedSoFar - alreadyClaimed;
        require(amount <= claimable, "DV: Amount exceeds claimable vested tokens");

        claimedAmount = alreadyClaimed + amount;

        emit TokensClaimed(devBeneficiary, amount);
        xToken.safeTransfer(devBeneficiary, amount);
    }

    /**
     * @notice Calculates the amount of tokens currently claimable (vested but not yet claimed).
     */
    function claimableAmount() public view returns (uint256) {
        return vestedAmount() - claimedAmount;
    }
}
