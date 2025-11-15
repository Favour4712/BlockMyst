// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/PuzzleManager.sol";
import "../src/core/SeasonManager.sol";
import "../src/tokens/ArtifactNFT.sol";
import "../src/leaderboard/LeaderboardManager.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ArtifactNFT
        console.log("Deploying ArtifactNFT...");
        ArtifactNFT artifactNFT = new ArtifactNFT();
        console.log("ArtifactNFT deployed at:", address(artifactNFT));

        // 2. Deploy LeaderboardManager
        console.log("Deploying LeaderboardManager...");
        LeaderboardManager leaderboardManager = new LeaderboardManager();
        console.log(
            "LeaderboardManager deployed at:",
            address(leaderboardManager)
        );

        // 3. Deploy PuzzleManager
        console.log("Deploying PuzzleManager...");
        PuzzleManager puzzleManager = new PuzzleManager();
        console.log("PuzzleManager deployed at:", address(puzzleManager));

        // 4. Deploy SeasonManager
        console.log("Deploying SeasonManager...");
        SeasonManager seasonManager = new SeasonManager();
        console.log("SeasonManager deployed at:", address(seasonManager));

        // 5. Set up connections
        console.log("\nSetting up contract connections...");

        // Set PuzzleManager as minter in ArtifactNFT
        artifactNFT.setMinter(address(puzzleManager));
        console.log("Set PuzzleManager as ArtifactNFT minter");

        // Set PuzzleManager in LeaderboardManager
        leaderboardManager.setPuzzleManager(address(puzzleManager));
        console.log("Set PuzzleManager in LeaderboardManager");

        // Set contracts in PuzzleManager
        puzzleManager.setArtifactNFT(address(artifactNFT));
        puzzleManager.setLeaderboardManager(address(leaderboardManager));
        console.log("Set ArtifactNFT and LeaderboardManager in PuzzleManager");

        // Set PuzzleManager in SeasonManager
        seasonManager.setPuzzleManager(address(puzzleManager));
        console.log("Set PuzzleManager in SeasonManager");

        // 6. Fund reward pool with 1 CELO (optional, can be done later)
        uint256 initialFunding = 1 ether;
        puzzleManager.fundRewardPool{value: initialFunding}();
        console.log("\nFunded PuzzleManager reward pool with 1 CELO");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("ArtifactNFT:", address(artifactNFT));
        console.log("LeaderboardManager:", address(leaderboardManager));
        console.log("PuzzleManager:", address(puzzleManager));
        console.log("SeasonManager:", address(seasonManager));
        console.log("\nSave these addresses for frontend integration!");
    }
}

