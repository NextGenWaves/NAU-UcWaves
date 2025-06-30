// FILE: script/DeployAll.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// --- Imports ---
import "../src/nau.sol";
import "../src/nauy.sol";
import "../src/naun.sol";
import "../src/controller.sol";
import "../src/stakingRewards.sol";
import "../src/devTeamVesting.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployAll is Script {
    address constant UNIVERSAL_ROUTER_ADDRESS = 0x6fF5693b99212Da76ad316178A184AB56D299b43;
    // Amounts for initial distribution
    uint256 constant RESERVE_OPS_ALLOCATION = 150_000_000 * 1e18;
    uint256 constant RESERVE_MKT_ALLOCATION = 100_000_000 * 1e18;
    uint256 constant STAKING_NAU_BUDGET = 350_000_000 * 1e18;
    uint256 constant STAKING_NAUY_BUDGET = 5_000_000 * 1e18;
    uint256 constant STAKING_NAUN_BUDGET = 5_000_000 * 1e18;
    uint256 constant DEV_VESTING_AMOUNT = 200_000_000 * 1e18;

    // Vesting Schedule Parameters
    uint256 constant CLIFF_SECONDS = 365 days;
    uint256 constant VESTING_SECONDS_AFTER_CLIFF = 2 * 365 days;

    function run() external {
        // Get wallet information from environment variables
        uint256 deployerPk = vm.envUint("WALLET_0_PK");
        uint256 developerPk = vm.envUint("WALLET_2_PK");
        uint256 reservePk = vm.envUint("WALLET_3_PK");
        uint256 stakingOpsPk = vm.envUint("WALLET_4_PK");

        address deployerAdmin = vm.addr(deployerPk);
        address devBeneficiaryAddress = vm.addr(developerPk);
        address reserveWalletAddress = vm.addr(reservePk);
        address stakingOpsWalletAddress = vm.addr(stakingOpsPk);
        address feeRecipientAddress = stakingOpsWalletAddress;

        require(deployerAdmin != address(0), "Missing WALLET_0_PK");
        require(devBeneficiaryAddress != address(0), "Missing WALLET_2_PK");
        require(reserveWalletAddress != address(0), "Missing WALLET_3_PK");
        require(stakingOpsWalletAddress != address(0), "Missing WALLET_4_PK");

        vm.startBroadcast(deployerPk);

        console.log("--- Deploying Contracts ---");
        console.log("Deployer/Admin:", deployerAdmin);

        // 1. Deploy Controller first
        Controller controller = new Controller(reserveWalletAddress);
        console.log("Controller deployed at:", address(controller));
        address controllerAddress = address(controller);

        // 2. Deploy all token contracts
        NAU nau = new NAU(
            deployerAdmin, controllerAddress, reserveWalletAddress, devBeneficiaryAddress, stakingOpsWalletAddress
        );
        NAUY nauy = new NAUY(deployerAdmin, controllerAddress);
        NAUN naun = new NAUN(deployerAdmin, controllerAddress);
        console.log("NAU, NAUY, and NAUN contracts deployed.");

        // --- Initial Token Distribution ---
        console.log("--- Distributing Initial Tokens ---");
        nau.transfer(reserveWalletAddress, RESERVE_OPS_ALLOCATION);
        nau.transfer(reserveWalletAddress, RESERVE_MKT_ALLOCATION);
        nau.transfer(stakingOpsWalletAddress, STAKING_NAU_BUDGET);
        nauy.transfer(stakingOpsWalletAddress, STAKING_NAUY_BUDGET);
        naun.transfer(stakingOpsWalletAddress, STAKING_NAUN_BUDGET);
        console.log("Initial token distribution complete.");

        // --- Deploy Staking Contracts ---
        StakingRewards nauStaking = new StakingRewards(address(nau), address(nau), deployerAdmin, feeRecipientAddress);
        StakingRewards nauyStaking =
            new StakingRewards(address(nauy), address(nauy), deployerAdmin, feeRecipientAddress);
        StakingRewards naunStaking =
            new StakingRewards(address(naun), address(naun), deployerAdmin, feeRecipientAddress);
        console.log("Staking contracts deployed.");

        // --- Grant Staking Roles ---
        bytes32 FUNDER_ROLE = nauStaking.FUNDER_ROLE();
        bytes32 RATE_SETTER_ROLE = nauStaking.RATE_SETTER_ROLE();
        nauStaking.grantRole(FUNDER_ROLE, stakingOpsWalletAddress);
        nauyStaking.grantRole(FUNDER_ROLE, stakingOpsWalletAddress);
        naunStaking.grantRole(FUNDER_ROLE, stakingOpsWalletAddress);
        nauStaking.grantRole(RATE_SETTER_ROLE, stakingOpsWalletAddress);
        nauyStaking.grantRole(RATE_SETTER_ROLE, stakingOpsWalletAddress);
        naunStaking.grantRole(RATE_SETTER_ROLE, stakingOpsWalletAddress);
        console.log("Staking roles granted to StakingOpsWallet:", stakingOpsWalletAddress);

        // --- Set Contract Exclusions ---

        nau.setIsExcludedFromMaxWallet(address(nauStaking), true);
        nau.setIsExcludedFromMaxTx(address(nauStaking), true);
        console.log("Excluding Uniswap Universal Router...");
        nau.setIsExcludedFromMaxWallet(UNIVERSAL_ROUTER_ADDRESS, true);
        nau.setIsExcludedFromMaxTx(UNIVERSAL_ROUTER_ADDRESS, true);
        console.log("Staking contract exclusions set.");

        // --- Deploy & Fund Vesting Contract ---
        DevTeamVesting devVesting = new DevTeamVesting(
            address(nau), devBeneficiaryAddress, DEV_VESTING_AMOUNT, CLIFF_SECONDS, VESTING_SECONDS_AFTER_CLIFF
        );
        nau.setIsExcludedFromMaxWallet(address(devVesting), true);

        nau.transfer(address(devVesting), DEV_VESTING_AMOUNT);
        console.log("Dev Team Vesting contract deployed and funded.");

        // --- Final Deployment Summary ---
        console.log("--- Deployment Summary ---");
        console.log("Controller:", controllerAddress);
        console.log("NAU:", address(nau));
        console.log("NAUY:", address(nauy));
        console.log("NAUN:", address(naun));
        console.log("NAU Staking:", address(nauStaking));
        console.log("NAUY Staking:", address(nauyStaking));
        console.log("NAUN Staking:", address(naunStaking));
        console.log("Dev Vesting:", address(devVesting));
        console.log("-------------------------");
        console.log(
            "Deployment complete. Next steps: Use the manual tool with StakingOpsWallet to fund and set rates for the staking contracts."
        );

        vm.stopBroadcast();
    }
}
