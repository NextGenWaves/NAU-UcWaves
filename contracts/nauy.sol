// FILE: src/nauy.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NAUY is ERC20, AccessControl {
    // --- State ---
    address public immutable controller;

    // --- Constructor ---
    constructor(address admin, address controllerAddress) ERC20("NAUY", "NAUY") {
        require(admin != address(0), "NAUY: Invalid admin address");
        require(controllerAddress != address(0), "NAUY: Invalid controller address");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        controller = controllerAddress;

        _mint(admin, 15_000_000 * 1e18);
    }

    // --- Internal Transfer Logic ---
    function _update(address from, address to, uint256 amount) internal override {
        super._update(from, to, amount);
    }

    // --- SECURE Mint Function ---
    function controllerMint(address to, uint256 amount) external {
        require(msg.sender == controller, "NAUY: Only controller can mint");
        _mint(to, amount);
    }

    // --- Admin Renunciation ---
    function renounceAdmin() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
