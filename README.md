# 🧬 North American Union @ucwaves Ecosystem

This repository contains the core smart contracts for the **North American Union @ucwaves Ecosystem** — a decentralized opinion-sharing mechanism built on [Base](https://base.org/). It includes three ERC-20 tokens: `NAU`, `NAUY`, and `NAUN`, and a `Controller` contract for minting and burning logic. It also includes a **Developer Vesting** contract and a **Staking contract** with three deployed instances:

- **NAU Staking**
- **NAUY Staking**
- **NAUN Staking**

We also created 3 UniswapV3 Liquidity Pools on Base:

- **NAU/USDC LP**
- **NAUY/USDC LP**
- **NAUN/USDC LP**

## 📜 Contracts Overview

| Contract                      | Purpose                                           |
| ----------------------------- | ------------------------------------------------- |
| `NAU.sol`                     | Governance token, finite supply                   |
| `NAUY.sol`                    | Opinion token minted for "YES" stance             |
| `NAUN.sol`                    | Opinion token minted for "NO" stance              |
| `Controller.sol`              | Handles conversion from NAU → NAUY/NAUN           |
| `StakingRewards.sol`          | Generic staking contract used for all 3 tokens    |
| `DevTeamVesting.sol`          | Vesting contract for developer token distribution |
| `deployAll.s.sol`             | Script for deploying the full stack               |
| `SetupControllerScript.s.sol` | Script for configuring roles and linking tokens   |

## ✅ Verified Contracts

| Contract Name    | BaseScan Link                                                                               |
| ---------------- | ------------------------------------------------------------------------------------------- |
| `NAU`            | [View on BaseScan](https://basescan.org/address/0x1c14d38B2e32C2F7df5176d51bA98027F1069115) |
| `NAUY`           | [View on BaseScan](https://basescan.org/address/0x45443A1992A744F9955e3d77B9899641DA8AF533) |
| `NAUN`           | [View on BaseScan](https://basescan.org/address/0x7594cF4177D9eEE56475f61eF0FfCac2f660e122) |
| `Controller`     | [View on BaseScan](https://basescan.org/address/0xa2f79620BB6c1773657EF4a16DC3B4bf3703A655) |
| `DevTeamVesting` | [View on BaseScan](https://basescan.org/address/0x7C01Cd4DFd9bE95B8642777d408fA070A5dbb865) |
| `Staking_NAU`    | [View on BaseScan](https://basescan.org/address/0xbfb3Fe19BcAed06732EeF3ABC4B2742Dc3F2F494) |
| `Staking_NAUY`   | [View on BaseScan](https://basescan.org/address/0xE470E9CE0Ed62d82BA725f32f5a013Ff4878730E) |
| `Staking_NAUN`   | [View on BaseScan](https://basescan.org/address/0x1fcf10C4c325f11Fbcba50aDAC0Fd7f2ad659F40) |
| `NAU/USDC LP`    | [View on BaseScan](https://basescan.org/address/0x8BD48c8C8f99cBe32b117741ca9C074c4A20Cd98) |
| `NAUY/USDC LP`   | [View on BaseScan](https://basescan.org/address/0x9DB95E2273cb8803Adb25D63E9E4342FF4547c0A) |
| `NAUN/USDC LP`   | [View on BaseScan](https://basescan.org/address/0x51CB08aa46ABE7F571260eB5BaC7fa4AB7B35e8d) |

## 💡 Key Features

- Immutable ERC-20 tokens with renounced ownership for full decentralization
- Controller contract with one-way NAU → NAUY/NAUN mint/burn logic
- Developer token vesting using time-based cliffs and schedules
- Staking for all three tokens to incentivize long-term holding
- Fully open-source, audited, and verifiable code

## 🔐 License

This project is open-sourced under the [MIT License](./LICENSE).

## 🛡️ Security

Please refer to [SECURITY.md](./SECURITY.md) for how to report vulnerabilities or issues responsibly.

## 🤝 Contributing

We welcome community contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) to get started.

## 🌐 Project Links

- 🌍 [Base L2](https://base.org/)
- 📊 [BaseScan Explorer](https://basescan.org/)
- 🧾 [UcWaves Project Overview and dApp/Staking](https://ucwaves.com)
