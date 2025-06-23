// FILE: src/naun.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NAUN is ERC20, AccessControl {
    // --- Events ---
    event CooldownExclusionSet(address indexed account, bool excluded);

    // --- State ---
    address public immutable controller;
    uint256 public constant COOLDOWN_TIME = 60; // 60 seconds
    mapping(address => uint256) public lastTxTimestamp;
    mapping(address => bool) public isExcludedFromCooldown;

    // --- Constructor ---
    constructor(address admin, address controllerAddress) ERC20("NAUN", "NAUN") {
        require(admin != address(0), "NAUN: Invalid admin address");
        require(controllerAddress != address(0), "NAUN: Invalid controller address");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        controller = controllerAddress;
        isExcludedFromCooldown[admin] = true;

        _mint(admin, 15_000_000 * 1e18);
    }

    // --- Admin-only Exclusion Function ---
    function setIsExcludedFromCooldown(address account, bool excluded) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "NAUN: Cannot exclude the zero address");
        isExcludedFromCooldown[account] = excluded;
        emit CooldownExclusionSet(account, excluded);
    }

    // --- Internal Transfer Logic ---
    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);

        // Cooldown check applies to transfers from regular user accounts
        if (from != address(0) && !isExcludedFromCooldown[from]) {
            require(block.timestamp >= lastTxTimestamp[from] + COOLDOWN_TIME, "NAUN: Cooldown in effect");
            lastTxTimestamp[from] = block.timestamp;
        }
    }

    // --- SECURE Mint Function ---
    function controllerMint(address to, uint256 amount) external {
        require(msg.sender == controller, "NAUN: Only controller can mint");
        _mint(to, amount);
    }

    // --- Admin Renunciation ---
    function renounceAdmin() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
