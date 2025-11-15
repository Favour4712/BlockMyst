// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/PuzzleManager.sol";

contract CreatePuzzleScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address puzzleManagerAddress = vm.envAddress("PUZZLE_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        PuzzleManager puzzleManager = PuzzleManager(
            payable(puzzleManagerAddress)
        );

        // Example: Create a sample puzzle
        string memory ipfsHash = "QmExampleHash123456789"; // Replace with real IPFS hash

        // Create answer hash for "blockchain" (example answer)
        bytes32 answerHash = keccak256(abi.encodePacked("blockchain"));

        uint256 reward = 0.1 ether; // 0.1 CELO reward
        uint256 difficulty = 2; // Medium difficulty
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 7 days; // Puzzle active for 7 days
        string memory category = "DeFi";

        uint256 puzzleId = puzzleManager.createPuzzle(
            ipfsHash,
            answerHash,
            reward,
            difficulty,
            startTime,
            endTime,
            category
        );

        console.log("Created puzzle with ID:", puzzleId);
        console.log("Answer hash:", uint256(answerHash));
        console.log("IPFS Hash:", ipfsHash);
        console.log("Reward:", reward);
        console.log("Difficulty:", difficulty);
        console.log("Category:", category);

        vm.stopBroadcast();
    }
}

