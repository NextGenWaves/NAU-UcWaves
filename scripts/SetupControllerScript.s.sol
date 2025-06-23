// FILE: script/SetupControllerScript.s.sol (FINAL, COMPLETE VERSION)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/controller.sol";
// FINAL UPDATE: Import all necessary token contracts
import "../src/nau.sol";
import "../src/nauy.sol";
import "../src/naun.sol";

contract SetupControllerScript is Script {
    // !!! IMPORTANT: Update these with the real addresses from your DeployAll run !!!
    address constant CONTROLLER_ADDRESS = 0xa2f79620BB6c1773657EF4a16DC3B4bf3703A655; // <<< TODO: REPLACE
    address constant NAU_ADDRESS = 0x1c14d38B2e32C2F7df5176d51bA98027F1069115; // <<< TODO: REPLACE
    address constant NAUY_ADDRESS = 0x45443A1992A744F9955e3d77B9899641DA8AF533; // <<< TODO: REPLACE
    address constant NAUN_ADDRESS = 0x7594cF4177D9eEE56475f61eF0FfCac2f660e122; // <<< TODO: REPLACE

    // --- External Addresses ---
    address constant BASE_USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base Mainnet USDC

    // Uniswap V3 Pools
    address constant POOL_FOR_NAU_PRICE = 0x8BD48c8C8f99cBe32b117741ca9C074c4A20Cd98; // <<< TODO: REPLACE
    address constant POOL_FOR_NAUY_PRICE = 0x9DB95E2273cb8803Adb25D63E9E4342FF4547c0A; // <<< TODO: REPLACE
    address constant POOL_FOR_NAUN_PRICE = 0x51CB08aa46ABE7F571260eB5BaC7fa4AB7B35e8d; // <<< TODO: REPLACE

    // For V3, they are different. We assume the price pool IS the LP pair for this example.
    address constant NAU_LP_PAIR_ADDRESS = POOL_FOR_NAU_PRICE; // <<< TODO: REPLACE IF DIFFERENT
    address constant NAUY_LP_PAIR_ADDRESS = POOL_FOR_NAUY_PRICE; // <<< TODO: REPLACE IF DIFFERENT
    address constant NAUN_LP_PAIR_ADDRESS = POOL_FOR_NAUN_PRICE; // <<< TODO: REPLACE IF DIFFERENT

    function run() external {
        Controller controller = Controller(CONTROLLER_ADDRESS);
        // FINAL UPDATE: Create instances of all three token contracts
        NAU nau = NAU(NAU_ADDRESS);
        NAUY nauy = NAUY(NAUY_ADDRESS);
        NAUN naun = NAUN(NAUN_ADDRESS);

        vm.startBroadcast();

        console.log("Executing Setup Script as Admin Account:", msg.sender);

        // --- Step 1: Link tokens to the Controller ---
        console.log("Linking token addresses to Controller...");
        controller.setTokenAddresses(NAU_ADDRESS, NAUY_ADDRESS, NAUN_ADDRESS);
        console.log("Token addresses linked.");

        // --- Step 2: Set Quote Token ---
        console.log("Setting Quote Token in Controller...");
        controller.setQuoteToken(BASE_USDC_ADDRESS);
        console.log("Quote Token set.");

        // --- Step 3: Set Uniswap Pools for Price Oracle ---
        console.log("Mapping tokens to their price pools...");
        controller.setPool(NAU_ADDRESS, POOL_FOR_NAU_PRICE);
        controller.setPool(NAUY_ADDRESS, POOL_FOR_NAUY_PRICE);
        controller.setPool(NAUN_ADDRESS, POOL_FOR_NAUN_PRICE);
        console.log("Pool mappings set.");

        // --- FINAL UPDATE - STEP 4: Set and exclude all LP pairs from restrictions ---
        console.log("Configuring LP Pair for NAU...");
        nau.setLpPair(NAU_LP_PAIR_ADDRESS, true);
        console.log("LP Pair for NAU configured and excluded from all limits.");

        console.log("Configuring LP Pair for NAUY...");
        nauy.setIsExcludedFromCooldown(NAUY_LP_PAIR_ADDRESS, true);
        console.log("LP Pair for NAUY excluded from cooldown.");

        console.log("Configuring LP Pair for NAUN...");
        naun.setIsExcludedFromCooldown(NAUN_LP_PAIR_ADDRESS, true);
        console.log("LP Pair for NAUN excluded from cooldown.");

        console.log("--- Controller and LP Pair Setup Complete ---");
        vm.stopBroadcast();
    }
}
