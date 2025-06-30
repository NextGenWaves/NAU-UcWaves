// FILE: script/SetupControllerScript.s.sol (FINAL, CLEAN VERSION)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/controller.sol";
import "../src/nau.sol";
import "../src/nauy.sol";
import "../src/naun.sol";

contract SetupControllerScript is Script {
    address constant CONTROLLER_ADDRESS = 0x9c55175284505A184d5e4ab52aA40d68f2253051;
    address constant NAU_ADDRESS = 0x1A7F059f6Bc234D1D03075B430e26c67856B53dE;
    address constant NAUY_ADDRESS = 0x8fE351FD35DDC08bc2f3c5fA573B44d6E13f97ec;
    address constant NAUN_ADDRESS = 0x885f14Ec5c427767A660174ea0EA8C9953f3549D;

    address constant BASE_USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address constant POOL_FOR_NAU_PRICE = 0x0c5E7572D136A745933c4a3a8BA9308Dbd05204E;
    address constant POOL_FOR_NAUY_PRICE = 0xBc667361E8eBC8fdC3E03e057724Fb20F4D6587E;
    address constant POOL_FOR_NAUN_PRICE = 0x11B10A4094D6c96154F20eC70810baCf425C4Fb9;

    address constant NAU_LP_PAIR_ADDRESS = POOL_FOR_NAU_PRICE;
    address constant NAUY_LP_PAIR_ADDRESS = POOL_FOR_NAUY_PRICE;
    address constant NAUN_LP_PAIR_ADDRESS = POOL_FOR_NAUN_PRICE;

    function run() external {
        Controller controller = Controller(CONTROLLER_ADDRESS);
        NAU nau = NAU(NAU_ADDRESS);
        vm.startBroadcast();

        console.log("Executing Setup Script as Admin Account:", msg.sender);

        // Step 1: Link tokens to controller
        console.log("Linking token addresses to Controller...");
        controller.setTokenAddresses(NAU_ADDRESS, NAUY_ADDRESS, NAUN_ADDRESS);
        console.log("Token addresses linked.");

        // Step 2: Set quote token
        console.log("Setting Quote Token in Controller...");
        controller.setQuoteToken(BASE_USDC_ADDRESS);
        console.log("Quote Token set.");

        // Step 3: Map tokens to their Uniswap price pools
        console.log("Mapping tokens to their price pools...");
        controller.setPool(NAU_ADDRESS, POOL_FOR_NAU_PRICE);
        controller.setPool(NAUY_ADDRESS, POOL_FOR_NAUY_PRICE);
        controller.setPool(NAUN_ADDRESS, POOL_FOR_NAUN_PRICE);
        console.log("Pool mappings set.");

        // Step 4: Configure LP pair exclusions
        console.log("Configuring LP Pair for NAU...");
        nau.setLpPair(NAU_LP_PAIR_ADDRESS, true);
        console.log("NAU LP pair excluded from limits.");

        console.log("--- Controller and LP Pair Setup Complete ---");
        vm.stopBroadcast();
    }
}
