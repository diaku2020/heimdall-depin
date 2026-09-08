# Heimdall • Camera-Free Spatial Radar & Vital Intelligence

[![Base L2](https://img.shields.io/badge/Blockchain-Base%20L2-blue)](https://basescan.org/token/0x452Ca685eF98C01e36E8Be33ae111146CB7891aD)
[![NFT Cap](https://img.shields.io/badge/NFT%20Supply-10%20Worldwide-purple)](https://github.com/diaku2020/heimdall-depin)
[![Hard-Asset Peg](https://img.shields.io/badge/Backing-17%25%20PAXG%20%2B%20cbBTC-gold)](https://github.com/diaku2020/heimdall-depin)

Official flagship production portal, smart contracts, and serverless payment rails for **Heimdall**, the ambient millimeter-wave spatial sensing and vital intelligence DePIN hardware network created by **Imani Rivers-Regist** (**RandRTech**).

---

## 🏛️ Hard-Asset Treasury & Dual-Peg Engine
- **Target Peg Formula**: 1.0 mg Physical Gold (XAU) + 100 Satoshis Bitcoin (BTC) per  token.
- **Hardware Sales Flywheel**: Exactly **17% of all hardware node sales** (.50 of every  unit) is automatically routed to purchase **Physical Gold (PAXG)** and **Bitcoin (cbBTC)**, deposited directly into smart contract reserve vaults on Base L2.
- **Perpetual Economic Loop**:
  - 🔥 **50% Burned Forever**: When paying in , half the tokens are permanently destroyed.
  - ♻️ **50% Recycled to Miners**: The other half returns directly to active Heimdall node operators.
  - 🏛️ **17% Hard-Asset Backing**: Every node sold continuously increases the asset floor.

---

## 💎 Strictly Capped 10-NFT Collection
- **Total Max Supply**: **Strictly 10 passes in existence worldwide**.
- 👑 **The 1-of-1 Sovereign Master** (*The Grand Bubble 11D Manifold*): Holder receives **5 Years of 100% FREE Physical Prototypes** dispatched directly to their door.
- 💎 **The 9 Genesis Collector Passes** (*11D Quasicrystal Series*): Holders receive **Lifetime Exclusive Access to the Secret Annual Prototype Store** (1 new experimental prototype released once a year).

---

## 📦 Smart Contracts & Infrastructure
- **contracts/HeimdallGenesisPass.sol**: ERC-721 contract hard-capped to 10 tokens with built-in 50% burn, 50% miner recycling, and on-chain entitlement verifiers.
- **contracts/HeimdallReserveRouter.sol**: Automated 17% hardware sales router swapping USDC into PAXG & cbBTC on Uniswap v3 / Base L2.
- **workers/stripe_treasury_webhook.js**: Cloudflare Worker handling Stripe checkout events, calculating the .50 allocation, and dispatching to the reserve router.
- **index.html**: The complete production frontend with Web3 wallet connection, dual-rail checkout (Stripe USD  vs  ), and token-gated prototype store.

---

## 🚀 1-Click Cloudflare Pages Deployment
1. Connect your Cloudflare account to GitHub: diaku2020/heimdall-depin.
2. Build command: None
3. Output directory: /
4. Set custom domain (e.g. 
iversandregist.com).

Developed by **RandRTech** • Founder & Principal Engineer: **Imani Rivers-Regist**.
