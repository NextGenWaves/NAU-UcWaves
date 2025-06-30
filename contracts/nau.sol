// FILE: src/nau.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NAU is ERC20, AccessControl {
    // --- Constants ---
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 1e18;
    uint256 public constant MAX_WALLET_PERCENT = 1300; // 13%
    uint256 public constant MAX_TX_AMOUNT = 10_000_000 * 1e18; // 10M NAU
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    // --- Events ---
    event MaxWalletExclusionSet(address indexed account, bool excluded);
    event MaxTxExclusionSet(address indexed account, bool excluded);
    event LpPairSet(address indexed pairAddress, bool isExcluded);

    // --- State ---
    mapping(address => bool) public isExcludedFromMaxWallet;
    mapping(address => bool) public isExcludedFromMaxTx;
    address public lpPair;

    // --- Immutable Addresses for Security ---
    address public immutable reserveWallet;
    address public immutable developerWallet;
    address public immutable stakingOpsWallet;
    address public immutable controller;

    // --- Constructor ---
    constructor(
        address admin,
        address controllerAddress,
        address reserveWalletAddress,
        address developerWalletAddress,
        address stakingOpsWalletAddress
    ) ERC20("NAU", "NAU") {
        require(admin != address(0), "Admin address cannot be zero");
        require(controllerAddress != address(0), "Controller cannot be zero address");
        require(reserveWalletAddress != address(0), "Reserve wallet cannot be zero");
        require(developerWalletAddress != address(0), "Developer wallet cannot be zero");
        require(stakingOpsWalletAddress != address(0), "Staking ops wallet cannot be zero");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        controller = controllerAddress;
        reserveWallet = reserveWalletAddress;
        developerWallet = developerWalletAddress;
        stakingOpsWallet = stakingOpsWalletAddress;

        isExcludedFromMaxWallet[reserveWallet] = true;
        isExcludedFromMaxWallet[developerWallet] = true;
        isExcludedFromMaxWallet[stakingOpsWallet] = true;
        isExcludedFromMaxWallet[admin] = true;

        isExcludedFromMaxTx[admin] = true;
        isExcludedFromMaxTx[stakingOpsWalletAddress] = true;

        _mint(admin, INITIAL_SUPPLY);
    }

    // --- Function to set LP Pair and exclude it from all relevant limits ---
    function setLpPair(address pairAddress, bool excluded) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(pairAddress != address(0), "NAU: Cannot set pair to zero address");

        lpPair = pairAddress;

        isExcludedFromMaxWallet[pairAddress] = excluded;
        isExcludedFromMaxTx[pairAddress] = excluded;

        emit LpPairSet(pairAddress, excluded);
    }

    // --- Admin-only Exclusion Functions ---
    function setIsExcludedFromMaxWallet(address account, bool excluded) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "NAU: Cannot exclude zero address");
        isExcludedFromMaxWallet[account] = excluded;
        emit MaxWalletExclusionSet(account, excluded);
    }

    function setIsExcludedFromMaxTx(address account, bool excluded) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "NAU: Cannot exclude zero address");
        isExcludedFromMaxTx[account] = excluded;
        emit MaxTxExclusionSet(account, excluded);
    }

    // --- Internal Transfer Logic ---
    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);

        if (from != address(0) && to != address(0) && !isExcludedFromMaxTx[from]) {
            require(amount <= MAX_TX_AMOUNT, "NAU: Transfer exceeds max tx amount");
        }

        if (to != address(0) && !isExcludedFromMaxWallet[to]) {
            require(
                balanceOf(to) <= (totalSupply() * MAX_WALLET_PERCENT) / BASIS_POINTS_DIVISOR,
                "NAU: Recipient exceeds max wallet limit"
            );
        }
    }

    // --- SECURE Burn Function ---
    function controllerBurn(address account, uint256 amount) external {
        require(msg.sender == controller, "NAU: Not authorized, only controller can burn");
        _burn(account, amount);
    }

    // --- Admin Renunciation ---
    function renounceAdmin() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
