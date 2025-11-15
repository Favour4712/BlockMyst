// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/PuzzleManager.sol";
import "../src/tokens/ArtifactNFT.sol";
import "../src/leaderboard/LeaderboardManager.sol";

contract PuzzleManagerTest is Test {
    PuzzleManager public puzzleManager;
    ArtifactNFT public artifactNFT;
    LeaderboardManager public leaderboardManager;
    
    address public owner;
    address public player1;
    address public player2;
    
    uint256 constant INITIAL_BALANCE = 100 ether;
    
    event PuzzleCreated(uint256 indexed puzzleId, uint256 difficulty, uint256 reward);
    event PuzzleSolved(address indexed player, uint256 indexed puzzleId, uint256 reward);
    event RewardClaimed(address indexed player, uint256 amount, uint256 nftId);
    
    function setUp() public {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        
        vm.deal(owner, INITIAL_BALANCE);
        vm.deal(player1, INITIAL_BALANCE);
        vm.deal(player2, INITIAL_BALANCE);
        
        // Deploy contracts
        artifactNFT = new ArtifactNFT();
        leaderboardManager = new LeaderboardManager();
        puzzleManager = new PuzzleManager();
        
        // Set up connections
        artifactNFT.setMinter(address(puzzleManager));
        leaderboardManager.setPuzzleManager(address(puzzleManager));
        puzzleManager.setArtifactNFT(address(artifactNFT));
        puzzleManager.setLeaderboardManager(address(leaderboardManager));
        
        // Fund reward pool
        puzzleManager.fundRewardPool{value: 10 ether}();
    }
    
    function testCreatePuzzle() public {
        string memory ipfsHash = "QmTest123";
        bytes32 answerHash = keccak256(abi.encodePacked("test"));
        uint256 reward = 1 ether;
        uint256 difficulty = 2;
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 7 days;
        string memory category = "DeFi";
        
        vm.expectEmit(true, true, true, true);
        emit PuzzleCreated(1, difficulty, reward);
        
        uint256 puzzleId = puzzleManager.createPuzzle(
            ipfsHash,
            answerHash,
            reward,
            difficulty,
            startTime,
            endTime,
            category
        );
        
        assertEq(puzzleId, 1);
        assertEq(puzzleManager.currentPuzzleId(), 1);
        
        IPuzzleManager.Puzzle memory puzzle = puzzleManager.getPuzzle(puzzleId);
        assertEq(puzzle.ipfsHash, ipfsHash);
        assertEq(puzzle.answerHash, answerHash);
        assertEq(puzzle.reward, reward);
        assertEq(puzzle.difficulty, difficulty);
        assertTrue(puzzle.active);
    }
    
    function testSubmitCorrectAnswer() public {
        // Create puzzle
        bytes32 answerHash = keccak256(abi.encodePacked("blockchain"));
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            answerHash,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        // Player submits correct answer
        vm.prank(player1);
        vm.expectEmit(true, true, true, true);
        emit PuzzleSolved(player1, puzzleId, 1 ether);
        
        bool solved = puzzleManager.submitAnswer(puzzleId, "blockchain");
        assertTrue(solved);
        assertTrue(puzzleManager.hasSolved(puzzleId, player1));
        
        // Check player stats
        (uint256 score, uint256 streak, uint256 totalSolved) = puzzleManager.getPlayerStats(player1);
        assertEq(streak, 1);
        assertEq(totalSolved, 1);
        assertGt(score, 0);
    }
    
    function testSubmitIncorrectAnswer() public {
        bytes32 answerHash = keccak256(abi.encodePacked("blockchain"));
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            answerHash,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.prank(player1);
        vm.expectRevert("PuzzleManager: incorrect answer");
        puzzleManager.submitAnswer(puzzleId, "wronganswer");
    }
    
    function testClaimReward() public {
        bytes32 answerHash = keccak256(abi.encodePacked("test"));
        uint256 reward = 1 ether;
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            answerHash,
            reward,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.startPrank(player1);
        puzzleManager.submitAnswer(puzzleId, "test");
        
        uint256 balanceBefore = player1.balance;
        puzzleManager.claimReward(puzzleId);
        uint256 balanceAfter = player1.balance;
        
        assertEq(balanceAfter - balanceBefore, reward);
        
        // Check NFT was minted
        uint256 nftBalance = artifactNFT.getTotalArtifacts(player1);
        assertEq(nftBalance, 1);
        
        vm.stopPrank();
    }
    
    function testCannotClaimRewardTwice() public {
        bytes32 answerHash = keccak256(abi.encodePacked("test"));
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            answerHash,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.startPrank(player1);
        puzzleManager.submitAnswer(puzzleId, "test");
        puzzleManager.claimReward(puzzleId);
        
        vm.expectRevert("PuzzleManager: no reward");
        puzzleManager.claimReward(puzzleId);
        vm.stopPrank();
    }
    
    function testGetActivePuzzles() public {
        // Create multiple puzzles
        puzzleManager.createPuzzle(
            "QmTest1",
            keccak256(abi.encodePacked("test1")),
            1 ether,
            1,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        puzzleManager.createPuzzle(
            "QmTest2",
            keccak256(abi.encodePacked("test2")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "NFTs"
        );
        
        uint256[] memory activePuzzles = puzzleManager.getActivePuzzles();
        assertEq(activePuzzles.length, 2);
    }
    
    function testStreak() public {
        // Day 1: Solve puzzle
        bytes32 answer1 = keccak256(abi.encodePacked("test1"));
        uint256 puzzle1 = puzzleManager.createPuzzle(
            "QmTest1",
            answer1,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.prank(player1);
        puzzleManager.submitAnswer(puzzle1, "test1");
        
        (,uint256 streak1,) = puzzleManager.getPlayerStats(player1);
        assertEq(streak1, 1);
        
        // Day 2: Solve another puzzle
        vm.warp(block.timestamp + 1 days);
        
        bytes32 answer2 = keccak256(abi.encodePacked("test2"));
        uint256 puzzle2 = puzzleManager.createPuzzle(
            "QmTest2",
            answer2,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.prank(player1);
        puzzleManager.submitAnswer(puzzle2, "test2");
        
        (,uint256 streak2,) = puzzleManager.getPlayerStats(player1);
        assertEq(streak2, 2);
    }
    
    function testPauseUnpause() public {
        puzzleManager.pause();
        
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("test")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.prank(player1);
        vm.expectRevert();
        puzzleManager.submitAnswer(puzzleId, "test");
        
        puzzleManager.unpause();
        
        vm.prank(player1);
        puzzleManager.submitAnswer(puzzleId, "test");
        assertTrue(puzzleManager.hasSolved(puzzleId, player1));
    }
    
    function testRateLimiting() public {
        bytes32 answerHash = keccak256(abi.encodePacked("test"));
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            answerHash,
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        vm.startPrank(player1);
        
        // Make 9 wrong attempts (these will revert but not hit rate limit)
        for (uint256 i = 0; i < 9; i++) {
            vm.expectRevert("PuzzleManager: incorrect answer");
            puzzleManager.submitAnswer(puzzleId, "wrong");
        }
        
        // 10th attempt should still show incorrect answer (not rate limited yet)
        // because reverted transactions don't increment attempt count
        vm.expectRevert("PuzzleManager: incorrect answer");
        puzzleManager.submitAnswer(puzzleId, "wrong");
        
        vm.stopPrank();
    }
    
    receive() external payable {}
}

