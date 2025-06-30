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
| `NAU`            | [View on BaseScan](https://basescan.org/address/0x1A7F059f6Bc234D1D03075B430e26c67856B53dE) |
| `NAUY`           | [View on BaseScan](https://basescan.org/address/0x8fE351FD35DDC08bc2f3c5fA573B44d6E13f97ec) |
| `NAUN`           | [View on BaseScan](https://basescan.org/address/0x885f14Ec5c427767A660174ea0EA8C9953f3549D) |
| `Controller`     | [View on BaseScan](https://basescan.org/address/0x9c55175284505A184d5e4ab52aA40d68f2253051) |
| `DevTeamVesting` | [View on BaseScan](https://basescan.org/address/0xD29c16A57462EfE0f51A778C3629303e1849bdFE) |
| `Staking_NAU`    | [View on BaseScan](https://basescan.org/address/0x399095b87f77eDD8d811cB69B51db81ca889d315) |
| `Staking_NAUY`   | [View on BaseScan](https://basescan.org/address/0xDb51A363bf304e9A0ef66C29496AE5F8F3ABeDA4) |
| `Staking_NAUN`   | [View on BaseScan](https://basescan.org/address/0xA2baEcb35ec71EE702Da05a73c8F3F5C4b44F77D) |
| `NAU/USDC LP`    | [View on BaseScan](https://basescan.org/address/0x0c5E7572D136A745933c4a3a8BA9308Dbd05204E) |
| `NAUY/USDC LP`   | [View on BaseScan](https://basescan.org/address/0xBc667361E8eBC8fdC3E03e057724Fb20F4D6587E) |
| `NAUN/USDC LP`   | [View on BaseScan](https://basescan.org/address/0x11B10A4094D6c96154F20eC70810baCf425C4Fb9) |

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
