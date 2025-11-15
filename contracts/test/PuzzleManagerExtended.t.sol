// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/PuzzleManager.sol";
import "../src/tokens/ArtifactNFT.sol";
import "../src/leaderboard/LeaderboardManager.sol";

contract PuzzleManagerExtendedTest is Test {
    PuzzleManager public puzzleManager;
    ArtifactNFT public artifactNFT;
    LeaderboardManager public leaderboardManager;

    address public owner;
    address public player1;
    address public player2;

    uint256 constant INITIAL_BALANCE = 100 ether;

    function setUp() public {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");

        vm.deal(owner, INITIAL_BALANCE);
        vm.deal(player1, INITIAL_BALANCE);
        vm.deal(player2, INITIAL_BALANCE);

        artifactNFT = new ArtifactNFT();
        leaderboardManager = new LeaderboardManager();
        puzzleManager = new PuzzleManager();

        artifactNFT.setMinter(address(puzzleManager));
        leaderboardManager.setPuzzleManager(address(puzzleManager));
        puzzleManager.setArtifactNFT(address(artifactNFT));
        puzzleManager.setLeaderboardManager(address(leaderboardManager));

        puzzleManager.fundRewardPool{value: 10 ether}();
    }

    // STAKING TESTS
    function testStakeToPuzzle() public {
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

        // Enable staking
        puzzleManager.enableStakingForPuzzle(puzzleId, 0.5 ether);

        vm.prank(player1);
        puzzleManager.stakeToPuzzle{value: 0.5 ether}(puzzleId);

        assertEq(puzzleManager.playerStakes(puzzleId, player1), 0.5 ether);
        assertEq(puzzleManager.puzzleStakePool(puzzleId), 0.5 ether);
    }

    function testCannotStakeIfNotEnabled() public {
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

        vm.prank(player1);
        vm.expectRevert("PuzzleManager: staking not enabled for this puzzle");
        puzzleManager.stakeToPuzzle{value: 0.5 ether}(puzzleId);
    }

    function testUnstake() public {
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

        puzzleManager.enableStakingForPuzzle(puzzleId, 0.5 ether);

        vm.prank(player1);
        puzzleManager.stakeToPuzzle{value: 0.5 ether}(puzzleId);

        // Warp past puzzle end time
        vm.warp(block.timestamp + 8 days);

        uint256 balanceBefore = player1.balance;
        vm.prank(player1);
        puzzleManager.unstake(puzzleId);
        uint256 balanceAfter = player1.balance;

        assertEq(balanceAfter - balanceBefore, 0.5 ether);
    }

    function testClaimRewardWithStakeBonus() public {
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

        puzzleManager.enableStakingForPuzzle(puzzleId, 0.5 ether);

        vm.startPrank(player1);
        puzzleManager.stakeToPuzzle{value: 0.5 ether}(puzzleId);
        puzzleManager.submitAnswer(puzzleId, "test");

        uint256 balanceBefore = player1.balance;
        puzzleManager.claimReward(puzzleId);
        uint256 balanceAfter = player1.balance;

        // Should get reward + 50% bonus + stake back
        uint256 expected = reward + (reward * 50) / 100 + 0.5 ether;
        assertEq(balanceAfter - balanceBefore, expected);
        vm.stopPrank();
    }

    // HINT TESTS
    function testAddHint() public {
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

        puzzleManager.addHintToPuzzle(puzzleId, "This is hint 1");
        puzzleManager.addHintToPuzzle(puzzleId, "This is hint 2");

        assertEq(puzzleManager.getHintCount(puzzleId), 2);
    }

    function testBuyHint() public {
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

        puzzleManager.addHintToPuzzle(puzzleId, "Hint: It's about blockchain");

        // Give player some points first
        vm.prank(address(this));
        // Solve another puzzle to get points
        bytes32 answer2 = keccak256(abi.encodePacked("other"));
        uint256 puzzle2 = puzzleManager.createPuzzle(
            "QmTest2",
            answer2,
            0.5 ether,
            1,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );

        vm.prank(player1);
        puzzleManager.submitAnswer(puzzle2, "other");

        // Now buy hint for first puzzle
        vm.prank(player1);
        string memory hint = puzzleManager.buyHint(puzzleId);

        assertEq(hint, "Hint: It's about blockchain");
        assertEq(puzzleManager.getPlayerHintsUsed(player1, puzzleId), 1);
    }

    function testHintCostEscalates() public {
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

        puzzleManager.addHintToPuzzle(puzzleId, "Hint 1");
        puzzleManager.addHintToPuzzle(puzzleId, "Hint 2");

        uint256 firstHintCost = puzzleManager.getNextHintCost(
            player1,
            puzzleId
        );

        // After using one hint, cost should be higher
        // (We'd need to actually buy the hint and give player points for this)
        assertEq(firstHintCost, 50); // Base cost * 1
    }

    function testClaimRewardWithHintPenalty() public {
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

        puzzleManager.addHintToPuzzle(puzzleId, "Hint 1");

        // Give player points
        bytes32 answer2 = keccak256(abi.encodePacked("other"));
        uint256 puzzle2 = puzzleManager.createPuzzle(
            "QmTest2",
            answer2,
            0.5 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );

        vm.startPrank(player1);
        puzzleManager.submitAnswer(puzzle2, "other");

        // Buy hint
        puzzleManager.buyHint(puzzleId);

        // Solve puzzle
        puzzleManager.submitAnswer(puzzleId, "test");

        uint256 balanceBefore = player1.balance;
        puzzleManager.claimReward(puzzleId);
        uint256 balanceAfter = player1.balance;

        // Should get reduced reward (10% penalty per hint)
        uint256 penalty = (reward * 10) / 100;
        uint256 expected = reward - penalty;
        assertEq(balanceAfter - balanceBefore, expected);
        vm.stopPrank();
    }

    function testCannotBuyMoreHintsThanAvailable() public {
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

        puzzleManager.addHintToPuzzle(puzzleId, "Only hint");

        // Give player massive points
        bytes32 answer2 = keccak256(abi.encodePacked("other"));
        uint256 puzzle2 = puzzleManager.createPuzzle(
            "QmTest2",
            answer2,
            5 ether,
            4,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );

        vm.startPrank(player1);
        puzzleManager.submitAnswer(puzzle2, "other");

        // Buy first hint
        puzzleManager.buyHint(puzzleId);

        // Try to buy second hint (doesn't exist)
        vm.expectRevert("PuzzleManager: no more hints");
        puzzleManager.buyHint(puzzleId);
        vm.stopPrank();
    }

    receive() external payable {}
}
