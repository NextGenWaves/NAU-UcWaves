// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/nau.sol";
import "../src/nauy.sol";
import "../src/naun.sol";
import "../src/controller.sol";

contract RenounceAll is Script {
    // ⚠️ Replace these with your deployed contract addresses
    address constant NAU_ADDRESS = 0x1c14d38B2e32C2F7df5176d51bA98027F1069115;
    address constant NAUY_ADDRESS = 0x45443A1992A744F9955e3d77B9899641DA8AF533;
    address constant NAUN_ADDRESS = 0x7594cF4177D9eEE56475f61eF0FfCac2f660e122;
    address constant CONTROLLER_ADDRESS = 0xa2f79620BB6c1773657EF4a16DC3B4bf3703A655;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("WALLET_0_PK");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Renouncing admin roles from:", deployerAddress);

        NAU nau = NAU(NAU_ADDRESS);
        NAUY nauy = NAUY(NAUY_ADDRESS);
        NAUN naun = NAUN(NAUN_ADDRESS);
        Controller controller = Controller(CONTROLLER_ADDRESS);

        // These call the renounceAdmin() helper functions you implemented
        nau.renounceAdmin();
        nauy.renounceAdmin();
        naun.renounceAdmin();
        controller.renounceAdmin();

        console.log("All DEFAULT_ADMIN_ROLEs have been renounced.");

        vm.stopBroadcast();
    }
}
