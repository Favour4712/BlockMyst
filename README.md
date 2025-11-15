# 🔐 BlockMyst - Blockchain Education Game

> **Solve blockchain puzzles. Earn CELO. Collect NFT artifacts. Climb the leaderboard.**

A mobile-first educational puzzle game built on Celo blockchain where players learn about blockchain technology by solving daily cipher puzzles and mysteries.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Celo](https://img.shields.io/badge/Built%20on-Celo-35D07F)](https://celo.org)
[![React Native](https://img.shields.io/badge/React%20Native-0.72-61DAFB)](https://reactnative.dev/)

---

## 📖 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Game Mechanics](#game-mechanics)
- [Tech Stack](#tech-stack)
- [Smart Contract Architecture](#smart-contract-architecture)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Smart Contract Deployment](#smart-contract-deployment)
- [Frontend Setup](#frontend-setup)
- [How to Play](#how-to-play)
- [Development Roadmap](#development-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

**Cipher Hunters** is an educational blockchain puzzle game where players:
- Solve daily cipher puzzles about blockchain concepts (DeFi, NFTs, consensus mechanisms, etc.)
- Earn CELO tokens as rewards for correct answers
- Collect unique NFT artifacts that prove their knowledge
- Compete on global leaderboards
- Participate in seasonal tournaments with big prize pools
- Progress through mystery story arcs

**Target Audience:** Crypto beginners, blockchain enthusiasts, students, and anyone wanting to learn while earning.

**Hackathon Track:** Education (with gaming elements)

---

## ✨ Features

### 🧩 Puzzle System
- **Daily Puzzles:** New blockchain-themed riddles every day
- **Difficulty Levels:** Easy, Medium, Hard, Expert (higher difficulty = bigger rewards)
- **Categories:** DeFi, NFTs, Consensus, Smart Contracts, Wallet Security, Tokenomics
- **Time-Limited:** Each puzzle has a deadline, rewarding speed and accuracy
- **Progressive Difficulty:** Puzzles get harder as you advance

### 🎮 Game Modes
- **Single Player:** Solve puzzles at your own pace
- **Daily Challenges:** 24-hour limited puzzles with bonus rewards
- **Tournaments:** Weekly/monthly competitions with leaderboards
- **Seasons:** Multi-puzzle story arcs with jackpot rewards
- **Streak Bonuses:** Solve consecutive days for multiplier rewards

### 🏆 Rewards System
- **CELO Tokens:** Instant payouts for correct answers
- **NFT Artifacts:** Unique collectibles minted on-chain
- **Rarity Tiers:** Common → Rare → Epic → Legendary NFTs
- **Leaderboard Prizes:** Top players earn bonus rewards
- **Streak Multipliers:** 7-day streak = 2x rewards, 30-day = 5x

### 📊 Leaderboard & Stats
- **Global Rankings:** Compete with players worldwide
- **Category Leaders:** Top scorers per puzzle category
- **Speed Rankings:** Fastest solvers
- **Streak Leaders:** Longest solving streaks
- **Collection Rankings:** Most NFT artifacts collected
- **Personal Stats:** Track your progress, solve time, earnings

### 🎨 NFT Collection
- **Unique Artifacts:** Each puzzle completion mints a unique NFT
- **Metadata Includes:** Puzzle category, difficulty, solve rank, timestamp
- **Tradeable:** Transfer or trade artifacts with other players
- **Set Bonuses:** Collect complete sets for special rewards
- **Visual Designs:** Mystery-themed artifact art (scrolls, keys, relics)

---

## 🎲 Game Mechanics

### How Puzzles Work
1. **Puzzle Release:** Admin creates puzzle with encrypted answer (keccak256 hash)
2. **Player Attempts:** Submit answer through app
3. **Verification:** Smart contract checks answer hash on-chain
4. **Reward Distribution:** Instant CELO transfer + NFT mint on correct answer
5. **Leaderboard Update:** Stats and rankings update automatically

### Reward Structure
| Difficulty | Base Reward | Solve Time Bonus | NFT Rarity |
|-----------|-------------|------------------|------------|
| Easy | 1 CELO | +0.5 CELO (top 10) | Common (90%) / Rare (10%) |
| Medium | 3 CELO | +1 CELO (top 10) | Common (70%) / Rare (25%) / Epic (5%) |
| Hard | 5 CELO | +2 CELO (top 10) | Rare (60%) / Epic (35%) / Legendary (5%) |
| Expert | 10 CELO | +5 CELO (top 10) | Epic (70%) / Legendary (30%) |

### Streak System
- **3 days:** 1.5x multiplier
- **7 days:** 2x multiplier + bonus NFT
- **14 days:** 3x multiplier
- **30 days:** 5x multiplier + legendary NFT

### Tournament System
- **Weekly Tournaments:** 5 puzzles, top 20 split prize pool
- **Monthly Championships:** 20 puzzles, top 50 earn rewards
- **Season Finals:** Complete entire season for jackpot (50-100 CELO)

---

## 🛠️ Tech Stack

### Blockchain
- **Network:** Celo (Mainnet/Alfajores Testnet)
- **Smart Contracts:** Solidity ^0.8.20
- **Development Framework:** Hardhat
- **Libraries:** OpenZeppelin (ERC-721, AccessControl, ReentrancyGuard)
- **Testing:** Hardhat (Chai, Ethers.js)

### Frontend
- **Framework:** React Native 0.72+
- **Language:** TypeScript
- **Navigation:** React Navigation
- **State Management:** React Context API / Zustand
- **Web3 Integration:** ethers.js v6
- **Wallet Connection:** WalletConnect v2
- **UI Components:** React Native Paper / Native Base
- **Animations:** React Native Reanimated
- **Storage:** AsyncStorage

### Backend (Optional)
- **API:** Node.js + Express (for puzzle creation & analytics)
- **Database:** MongoDB / PostgreSQL (off-chain data caching)
- **File Storage:** IPFS (Pinata/NFT.Storage for puzzle content & NFT metadata)
- **Notifications:** Firebase Cloud Messaging

### DevOps
- **Version Control:** Git/GitHub
- **CI/CD:** GitHub Actions
- **Deployment:** Expo EAS Build (mobile) / Vercel (web dashboard)
- **Monitoring:** Sentry (error tracking)

---

## 🏗️ Smart Contract Architecture

### Core Contracts

#### 1. **PuzzleManager.sol**
Main game logic contract handling puzzle creation, answer verification, and reward distribution.

**Key Functions:**
- `createPuzzle()` - Admin creates new puzzle
- `submitAnswer()` - Players submit solutions
- `claimReward()` - Claim CELO + mint NFT
- `getPuzzle()` - Fetch puzzle details
- `getPlayerStats()` - Get player statistics

#### 2. **ArtifactNFT.sol** (ERC-721)
NFT contract for minting and managing artifact collectibles.

**Key Functions:**
- `mintArtifact()` - Mint NFT reward (called by PuzzleManager)
- `getPlayerArtifacts()` - Fetch player's NFT collection
- `getArtifactDetails()` - Get NFT metadata
- `tokenURI()` - Return IPFS metadata URI

#### 3. **LeaderboardManager.sol**
Manages global rankings, tournaments, and player statistics.

**Key Functions:**
- `createTournament()` - Start new tournament
- `updatePlayerStats()` - Update after puzzle solve
- `getGlobalLeaderboard()` - Fetch top players
- `getTournamentLeaderboard()` - Tournament rankings

#### 4. **SeasonManager.sol** (Optional)
Handles seasonal story arcs and multi-puzzle mysteries.

**Key Functions:**
- `createSeason()` - Create new mystery season
- `completeSeasonPuzzle()` - Mark season puzzle solved
- `claimSeasonReward()` - Claim jackpot after season completion

**Contract Interaction Flow:**
```
Player → PuzzleManager.submitAnswer()
         ↓
      [Verify Answer Hash]
         ↓
      PuzzleManager.claimReward()
         ↓
      ├─→ Transfer CELO
      ├─→ ArtifactNFT.mintArtifact()
      └─→ LeaderboardManager.updatePlayerStats()
```

See [Smart Contract Architecture Doc](./docs/ARCHITECTURE.md) for detailed technical specs.

---

## 📦 Installation

### Prerequisites
- Node.js v18+ and npm/yarn
- React Native development environment ([setup guide](https://reactnative.dev/docs/environment-setup))
- Hardhat for smart contract development
- Expo CLI (optional, recommended)
- Celo Wallet (Valora/MetaMask configured for Celo)

### Clone Repository
```bash
git clone https://github.com/yourusername/cipher-hunters.git
cd cipher-hunters
```

### Install Dependencies

**Smart Contracts:**
```bash
cd contracts
npm install
```

**Mobile App:**
```bash
cd mobile
npm install
# or
yarn install
```

---

## 📁 Project Structure

```
cipher-hunters/
├── contracts/                # Smart contracts
│   ├── src/
│   │   ├── PuzzleManager.sol
│   │   ├── ArtifactNFT.sol
│   │   ├── LeaderboardManager.sol
│   │   └── SeasonManager.sol
│   ├── test/                 # Contract tests
│   ├── scripts/              # Deployment scripts
│   └── hardhat.config.js
│
├── mobile/                   # React Native app
│   ├── src/
│   │   ├── components/       # Reusable UI components
│   │   ├── screens/          # App screens
│   │   │   ├── HomeScreen.tsx
│   │   │   ├── PuzzleScreen.tsx
│   │   │   ├── CollectionScreen.tsx
│   │   │   └── LeaderboardScreen.tsx
│   │   ├── services/         # Web3 & API services
│   │   │   ├── web3Service.ts
│   │   │   └── contractService.ts
│   │   ├── hooks/            # Custom React hooks
│   │   ├── utils/            # Helper functions
│   │   ├── navigation/       # Navigation setup
│   │   └── App.tsx
│   ├── assets/               # Images, fonts
│   └── package.json
│
├── backend/                  # Optional API server
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   └── services/
│   └── package.json
│
├── docs/                     # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── DEPLOYMENT.md
│
└── README.md
```

---

## 🚀 Smart Contract Deployment

### 1. Configure Environment
Create `.env` file in `/contracts`:
```env
PRIVATE_KEY=your_private_key_here
CELO_RPC_URL=https://alfajores-forno.celo-testnet.org
CELOSCAN_API_KEY=your_celoscan_api_key
```

### 2. Compile Contracts
```bash
cd contracts
npx hardhat compile
```

### 3. Run Tests
```bash
npx hardhat test
```

### 4. Deploy to Alfajores Testnet
```bash
npx hardhat run scripts/deploy.js --network alfajores
```

**Expected Output:**
```
Deploying ArtifactNFT...
ArtifactNFT deployed to: 0x1234...
Deploying LeaderboardManager...
LeaderboardManager deployed to: 0x5678...
Deploying PuzzleManager...
PuzzleManager deployed to: 0x9abc...
```

### 5. Verify Contracts
```bash
npx hardhat verify --network alfajores DEPLOYED_CONTRACT_ADDRESS
```

### 6. Save Contract Addresses
Update `/mobile/src/config/contracts.ts`:
```typescript
export const CONTRACTS = {
  PUZZLE_MANAGER: '0x9abc...',
  ARTIFACT_NFT: '0x1234...',
  LEADERBOARD_MANAGER: '0x5678...',
};
```

---

## 📱 Frontend Setup

### 1. Configure WalletConnect
Get Project ID from [WalletConnect Cloud](https://cloud.walletconnect.com)

Update `/mobile/src/config/walletconnect.ts`:
```typescript
export const WALLET_CONNECT_PROJECT_ID = 'your_project_id';
```

### 2. Run Development Server

**Using Expo:**
```bash
cd mobile
npx expo start
```

**Using React Native CLI:**
```bash
# iOS
npx react-native run-ios

# Android
npx react-native run-android
```

### 3. Connect Wallet
- Open app on device/simulator
- Tap "Connect Wallet"
- Scan QR code with Valora or MetaMask Mobile
- Switch to Alfajores testnet

### 4. Get Test CELO
Visit [Celo Faucet](https://faucet.celo.org) and fund your wallet with test CELO.

---

## 🎮 How to Play

### For Players

1. **Connect Wallet**
   - Install Valora or configure MetaMask for Celo
   - Connect wallet in-app
   - Ensure you have CELO for gas fees

2. **Browse Puzzles**
   - Check daily puzzle on home screen
   - Browse by difficulty/category
   - View reward amounts

3. **Solve Puzzle**
   - Read the cipher/riddle
   - Enter your answer
   - Submit (costs small gas fee)
   - Wait for confirmation

4. **Claim Reward**
   - Tap "Claim Reward" after solving
   - Receive CELO tokens instantly
   - NFT artifact minted to your wallet

5. **Track Progress**
   - View stats on profile screen
   - Check leaderboard ranking
   - Browse NFT collection
   - Monitor streak bonuses

### For Admins

1. **Create Puzzle**
   ```javascript
   // Using admin dashboard or script
   await puzzleManager.createPuzzle(
     "ipfs://puzzle-content-hash",
     keccak256("correct_answer"),
     ethers.utils.parseEther("5"), // 5 CELO reward
     3, // Hard difficulty
     startTime,
     endTime,
     "DeFi"
   );
   ```

2. **Fund Reward Pool**
   ```javascript
   await puzzleManager.fundRewardPool({ 
     value: ethers.utils.parseEther("1000") 
   });
   ```

3. **Monitor Activity**
   - View solve rates
   - Check leaderboards
   - Analyze popular categories
   - Track reward distribution

---

## 🗺️ Development Roadmap

### Phase 1: MVP (Current)
- [x] Smart contract architecture
- [x] Basic puzzle system
- [x] NFT minting
- [x] Simple leaderboard
- [ ] Mobile app UI
- [ ] Wallet integration
- [ ] Deploy to testnet

### Phase 2: Core Features
- [ ] Tournament system
- [ ] Season/story arcs
- [ ] Advanced leaderboards
- [ ] Push notifications
- [ ] Social sharing
- [ ] Achievement badges

### Phase 3: Enhancement
- [ ] Multiplayer puzzle races
- [ ] Community-created puzzles
- [ ] NFT marketplace integration
- [ ] Cross-chain bridges
- [ ] DAO governance
- [ ] Mobile app optimization

### Phase 4: Scale
- [ ] Mainnet launch
- [ ] Marketing campaign
- [ ] Educational partnerships
- [ ] Sponsorship integration
- [ ] Multi-language support
- [ ] Advanced analytics dashboard

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

### How to Contribute
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Areas We Need Help
- Frontend UI/UX improvements
- Puzzle content creation
- Smart contract optimization
- Testing and QA
- Documentation
- Translations

---

## 📊 Demo & Screenshots

### Demo Video
🎥 [Watch 4-minute demo on YouTube](https://youtube.com/your-demo-link)

### Screenshots
*(Add screenshots here)*
- Home screen with daily puzzle
- Puzzle solving interface
- NFT collection gallery
- Leaderboard view

---

## 🧪 Testing

### Run Smart Contract Tests
```bash
cd contracts
npx hardhat test
npx hardhat coverage
```

### Run Frontend Tests
```bash
cd mobile
npm test
```

### Test on Testnet
1. Deploy contracts to Alfajores
2. Run mobile app in dev mode
3. Connect testnet wallet
4. Test full user flow

---

## 🔒 Security

- Smart contracts audited by [Audit Firm Name] *(pending)*
- Bug bounty program active
- Report vulnerabilities to: security@cipherhunters.io

**Security Best Practices:**
- Never store plaintext answers on-chain
- Use keccak256 hashing for answer verification
- Implement reentrancy guards on reward claims
- Time-lock puzzle releases
- Rate limit submissions

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](./LICENSE) file for details.

---

## 👥 Team

- **Your Name** - Lead Developer - [@yourhandle](https://github.com/yourhandle)
- **Team Member 2** - Smart Contract Developer
- **Team Member 3** - Frontend Developer

---

## 🙏 Acknowledgments

- Built for **Celo Composer Hackathon**
- Powered by [Celo](https://celo.org) blockchain
- UI inspired by mystery/detective games
- Thanks to OpenZeppelin for secure contract libraries

---

## 📞 Contact & Links

- **Website:** https://cipherhunters.io
- **Twitter:** [@CipherHunters](https://twitter.com/cipherhunters)
- **Discord:** [Join our community](https://discord.gg/cipherhunters)
- **Email:** hello@cipherhunters.io
- **GitHub:** [github.com/yourusername/cipher-hunters](https://github.com/yourusername/cipher-hunters)

---

## 💡 FAQ

**Q: Do I need crypto experience to play?**  
A: No! The game teaches you blockchain concepts as you play.

**Q: How do I get CELO to start?**  
A: Use the [Celo Faucet](https://faucet.celo.org) for testnet or buy on exchanges for mainnet.

**Q: Can I play without connecting a wallet?**  
A: No, wallet connection is required to earn rewards and mint NFTs.

**Q: Are the NFTs tradeable?**  
A: Yes! They're standard ERC-721 tokens you can trade on any Celo NFT marketplace.

**Q: How often are new puzzles released?**  
A: Daily puzzles every 24 hours, plus special tournament puzzles weekly.

**Q: What happens if I get the answer wrong?**  
A: You can try again! No penalty except gas fees.

---

**Built with ❤️ for the Celo community**

*Learn blockchain. Earn crypto. Collect artifacts. Become a Cipher Hunter.* 🔐
