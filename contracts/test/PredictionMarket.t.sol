// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/competitive/PredictionMarket.sol";
import "../src/interfaces/IPredictionMarket.sol";
import "../src/core/PuzzleManager.sol";

contract PredictionMarketTest is Test {
    PredictionMarket public predictionMarket;
    PuzzleManager public puzzleManager;
    
    address public owner;
    address public bettor1;
    address public bettor2;
    address public solver1;
    address public solver2;
    
    event PredictionCreated(uint256 indexed predictionId, uint256 indexed puzzleId);
    event BetPlaced(uint256 indexed predictionId, address indexed bettor, address indexed predictedSolver, uint256 amount);
    event PredictionResolved(uint256 indexed predictionId, address indexed winner);
    event WinningsClaimed(uint256 indexed predictionId, address indexed bettor, uint256 amount);
    
    function setUp() public {
        owner = address(this);
        bettor1 = makeAddr("bettor1");
        bettor2 = makeAddr("bettor2");
        solver1 = makeAddr("solver1");
        solver2 = makeAddr("solver2");
        
        vm.deal(bettor1, 10 ether);
        vm.deal(bettor2, 10 ether);
        vm.deal(solver1, 10 ether);
        
        puzzleManager = new PuzzleManager();
        predictionMarket = new PredictionMarket();
        
        predictionMarket.setPuzzleManager(address(puzzleManager));
        puzzleManager.fundRewardPool{value: 10 ether}();
    }
    
    function testCreatePrediction() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](2);
        predictedSolvers[0] = solver1;
        predictedSolvers[1] = solver2;
        
        uint256 duration = 6 days;
        
        vm.expectEmit(true, true, false, false);
        emit PredictionCreated(1, puzzleId);
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, duration);
        
        assertEq(predictionId, 1);
        
        IPredictionMarket.Prediction memory prediction = predictionMarket.getPrediction(predictionId);
        assertEq(prediction.puzzleId, puzzleId);
        assertEq(prediction.predictedSolvers.length, 2);
        assertFalse(prediction.resolved);
    }
    
    function testPlaceBet() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        uint256 betAmount = 0.5 ether;
        
        vm.prank(bettor1);
        vm.expectEmit(true, true, true, true);
        emit BetPlaced(predictionId, bettor1, solver1, betAmount);
        
        predictionMarket.placeBet{value: betAmount}(predictionId, solver1);
        
        IPredictionMarket.Prediction memory prediction = predictionMarket.getPrediction(predictionId);
        assertEq(prediction.totalPool, betAmount);
    }
    
    function testMultipleBets() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](2);
        predictedSolvers[0] = solver1;
        predictedSolvers[1] = solver2;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
        
        vm.prank(bettor2);
        predictionMarket.placeBet{value: 0.5 ether}(predictionId, solver2);
        
        IPredictionMarket.Prediction memory prediction = predictionMarket.getPrediction(predictionId);
        assertEq(prediction.totalPool, 1.5 ether);
    }
    
    function testCannotBetBelowMinimum() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        vm.expectRevert("PredictionMarket: bet too small");
        predictionMarket.placeBet{value: 0.005 ether}(predictionId, solver1);
    }
    
    function testCannotBetAfterEnd() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        uint256 duration = 1 days;
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, duration);
        
        vm.warp(block.timestamp + 2 days);
        
        vm.prank(bettor1);
        vm.expectRevert("PredictionMarket: prediction ended");
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
    }
    
    function testResolvePrediction() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
        
        vm.expectEmit(true, true, false, false);
        emit PredictionResolved(predictionId, solver1);
        
        // Only puzzleManager can resolve
        vm.prank(address(puzzleManager));
        predictionMarket.resolvePrediction(predictionId, solver1);
        
        IPredictionMarket.Prediction memory prediction = predictionMarket.getPrediction(predictionId);
        assertTrue(prediction.resolved);
        assertEq(prediction.actualSolver, solver1);
    }
    
    function testClaimWinnings() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](2);
        predictedSolvers[0] = solver1;
        predictedSolvers[1] = solver2;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
        
        vm.prank(bettor2);
        predictionMarket.placeBet{value: 0.5 ether}(predictionId, solver2);
        
        // Resolve
        vm.prank(address(puzzleManager));
        predictionMarket.resolvePrediction(predictionId, solver1);
        
        uint256 balanceBefore = bettor1.balance;
        
        vm.prank(bettor1);
        predictionMarket.claimWinnings(predictionId);
        
        uint256 balanceAfter = bettor1.balance;
        assertGt(balanceAfter, balanceBefore);
    }
    
    function testCannotClaimTwice() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
        
        vm.prank(address(puzzleManager));
        predictionMarket.resolvePrediction(predictionId, solver1);
        
        vm.startPrank(bettor1);
        predictionMarket.claimWinnings(predictionId);
        
        vm.expectRevert("PredictionMarket: no winnings");
        predictionMarket.claimWinnings(predictionId);
        vm.stopPrank();
    }
    
    function testLosingBettorCannotClaim() public {
        uint256 puzzleId = puzzleManager.createPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](2);
        predictedSolvers[0] = solver1;
        predictedSolvers[1] = solver2;
        
        uint256 predictionId = predictionMarket.createPrediction(puzzleId, predictedSolvers, 6 days);
        
        vm.prank(bettor1);
        predictionMarket.placeBet{value: 1 ether}(predictionId, solver1);
        
        vm.prank(bettor2);
        predictionMarket.placeBet{value: 0.5 ether}(predictionId, solver2);
        
        vm.prank(address(puzzleManager));
        predictionMarket.resolvePrediction(predictionId, solver1);
        
        vm.prank(bettor2);
        vm.expectRevert("PredictionMarket: no winnings");
        predictionMarket.claimWinnings(predictionId);
    }
    
    function testGetActivePredictions() public {
        uint256 puzzle1 = puzzleManager.createPuzzle(
            "QmTest1",
            keccak256(abi.encodePacked("answer1")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        uint256 puzzle2 = puzzleManager.createPuzzle(
            "QmTest2",
            keccak256(abi.encodePacked("answer2")),
            1 ether,
            2,
            block.timestamp,
            block.timestamp + 7 days,
            "DeFi"
        );
        
        address[] memory predictedSolvers = new address[](1);
        predictedSolvers[0] = solver1;
        
        predictionMarket.createPrediction(puzzle1, predictedSolvers, 6 days);
        predictionMarket.createPrediction(puzzle2, predictedSolvers, 6 days);
        
        uint256[] memory activeMarkets = predictionMarket.getActivePredictions();
        assertEq(activeMarkets.length, 2);
    }
    
    receive() external payable {}
}
