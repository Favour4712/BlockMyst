// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/PuzzleManager.sol";
import "../src/core/SeasonManager.sol";
import "../src/tokens/ArtifactNFT.sol";
import "../src/leaderboard/LeaderboardManager.sol";
import "../src/gamification/AchievementManager.sol";
import "../src/gamification/ReferralManager.sol";
import "../src/gamification/ProgressionManager.sol";
import "../src/social/GuildManager.sol";
import "../src/competitive/BattleRoyale.sol";
import "../src/community/PuzzleCreator.sol";
import "../src/competitive/PredictionMarket.sol";
import "../src/marketplace/ArtifactMarketplace.sol";

contract DeployAllScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== DEPLOYING BLOCKMYST CONTRACTS ===\n");

        // 1. Deploy Core NFT and Token Contracts
        console.log("1. Deploying ArtifactNFT...");
        ArtifactNFT artifactNFT = new ArtifactNFT();
        console.log("   ArtifactNFT:", address(artifactNFT));

        // 2. Deploy Gamification Contracts
        console.log("\n2. Deploying Gamification Contracts...");
        
        console.log("   - AchievementManager...");
        AchievementManager achievementManager = new AchievementManager();
        console.log("     AchievementManager:", address(achievementManager));
        
        console.log("   - ReferralManager...");
        ReferralManager referralManager = new ReferralManager();
        console.log("     ReferralManager:", address(referralManager));
        
        console.log("   - ProgressionManager...");
        ProgressionManager progressionManager = new ProgressionManager();
        console.log("     ProgressionManager:", address(progressionManager));

        // 3. Deploy Social Contracts
        console.log("\n3. Deploying Social Contracts...");
        
        console.log("   - GuildManager...");
        GuildManager guildManager = new GuildManager();
        console.log("     GuildManager:", address(guildManager));

        // 4. Deploy Leaderboard and Competition
        console.log("\n4. Deploying Competition Contracts...");
        
        console.log("   - LeaderboardManager...");
        LeaderboardManager leaderboardManager = new LeaderboardManager();
        console.log("     LeaderboardManager:", address(leaderboardManager));
        
        console.log("   - BattleRoyale...");
        BattleRoyale battleRoyale = new BattleRoyale();
        console.log("     BattleRoyale:", address(battleRoyale));
        
        console.log("   - PredictionMarket...");
        PredictionMarket predictionMarket = new PredictionMarket();
        console.log("     PredictionMarket:", address(predictionMarket));

        // 5. Deploy Community and Marketplace
        console.log("\n5. Deploying Community Contracts...");
        
        console.log("   - PuzzleCreator...");
        PuzzleCreator puzzleCreator = new PuzzleCreator();
        console.log("     PuzzleCreator:", address(puzzleCreator));
        
        console.log("   - ArtifactMarketplace...");
        ArtifactMarketplace marketplace = new ArtifactMarketplace(address(artifactNFT));
        console.log("     ArtifactMarketplace:", address(marketplace));

        // 6. Deploy Main Game Contracts
        console.log("\n6. Deploying Main Game Contracts...");
        
        console.log("   - PuzzleManager...");
        PuzzleManager puzzleManager = new PuzzleManager();
        console.log("     PuzzleManager:", address(puzzleManager));
        
        console.log("   - SeasonManager...");
        SeasonManager seasonManager = new SeasonManager();
        console.log("     SeasonManager:", address(seasonManager));

        // 7. Set up all connections
        console.log("\n7. Setting up contract connections...");
        
        // PuzzleManager connections
        console.log("   - Connecting PuzzleManager...");
        puzzleManager.setArtifactNFT(address(artifactNFT));
        puzzleManager.setLeaderboardManager(address(leaderboardManager));
        puzzleManager.setAchievementManager(address(achievementManager));
        puzzleManager.setReferralManager(address(referralManager));
        puzzleManager.setGuildManager(address(guildManager));
        puzzleManager.setProgressionManager(address(progressionManager));
        
        // ArtifactNFT permissions
        console.log("   - Setting ArtifactNFT permissions...");
        artifactNFT.setMinter(address(puzzleManager));
        
        // LeaderboardManager
        console.log("   - Connecting LeaderboardManager...");
        leaderboardManager.setPuzzleManager(address(puzzleManager));
        
        // SeasonManager
        console.log("   - Connecting SeasonManager...");
        seasonManager.setPuzzleManager(address(puzzleManager));
        
        // AchievementManager
        console.log("   - Connecting AchievementManager...");
        achievementManager.setAuthorizedCaller(address(puzzleManager), true);
        
        // ReferralManager
        console.log("   - Connecting ReferralManager...");
        referralManager.setPuzzleManager(address(puzzleManager));
        referralManager.setAchievementManager(address(achievementManager));
        
        // GuildManager
        console.log("   - Connecting GuildManager...");
        guildManager.setPuzzleManager(address(puzzleManager));
        
        // ProgressionManager
        console.log("   - Connecting ProgressionManager...");
        progressionManager.setPuzzleManager(address(puzzleManager));
        
        // BattleRoyale
        console.log("   - Connecting BattleRoyale...");
        battleRoyale.setPuzzleManager(address(puzzleManager));
        
        // PuzzleCreator
        console.log("   - Connecting PuzzleCreator...");
        puzzleCreator.setPuzzleManager(address(puzzleManager));
        puzzleCreator.setProgressionManager(address(progressionManager));
        
        // PredictionMarket
        console.log("   - Connecting PredictionMarket...");
        predictionMarket.setPuzzleManager(address(puzzleManager));

        // 8. Fund initial pools
        console.log("\n8. Funding initial reward pools...");
        uint256 initialFunding = 1 ether;
        puzzleManager.fundRewardPool{value: initialFunding}();
        console.log("   - Funded PuzzleManager with 1 CELO");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n=== DEPLOYMENT COMPLETE ===\n");
        console.log("CORE CONTRACTS:");
        console.log("  ArtifactNFT:            ", address(artifactNFT));
        console.log("  PuzzleManager:          ", address(puzzleManager));
        console.log("  SeasonManager:          ", address(seasonManager));
        console.log("\nGAMIFICATION:");
        console.log("  AchievementManager:     ", address(achievementManager));
        console.log("  ReferralManager:        ", address(referralManager));
        console.log("  ProgressionManager:     ", address(progressionManager));
        console.log("\nSOCIAL:");
        console.log("  GuildManager:           ", address(guildManager));
        console.log("\nCOMPETITIVE:");
        console.log("  LeaderboardManager:     ", address(leaderboardManager));
        console.log("  BattleRoyale:           ", address(battleRoyale));
        console.log("  PredictionMarket:       ", address(predictionMarket));
        console.log("\nCOMMUNITY:");
        console.log("  PuzzleCreator:          ", address(puzzleCreator));
        console.log("  ArtifactMarketplace:    ", address(marketplace));
        console.log("\n=================================\n");
        console.log("Save these addresses for frontend integration!");
        console.log("Export them to your .env file:");
        console.log("\nARTIFACT_NFT_ADDRESS=", address(artifactNFT));
        console.log("PUZZLE_MANAGER_ADDRESS=", address(puzzleManager));
        console.log("SEASON_MANAGER_ADDRESS=", address(seasonManager));
        console.log("ACHIEVEMENT_MANAGER_ADDRESS=", address(achievementManager));
        console.log("REFERRAL_MANAGER_ADDRESS=", address(referralManager));
        console.log("PROGRESSION_MANAGER_ADDRESS=", address(progressionManager));
        console.log("GUILD_MANAGER_ADDRESS=", address(guildManager));
        console.log("LEADERBOARD_MANAGER_ADDRESS=", address(leaderboardManager));
        console.log("BATTLE_ROYALE_ADDRESS=", address(battleRoyale));
        console.log("PREDICTION_MARKET_ADDRESS=", address(predictionMarket));
        console.log("PUZZLE_CREATOR_ADDRESS=", address(puzzleCreator));
        console.log("MARKETPLACE_ADDRESS=", address(marketplace));
    }
}

