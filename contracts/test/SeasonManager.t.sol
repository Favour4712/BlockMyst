// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/SeasonManager.sol";
import "../src/core/PuzzleManager.sol";

contract SeasonManagerTest is Test {
    SeasonManager public seasonManager;
    PuzzleManager public puzzleManager;
    
    address public owner;
    address public player1;
    address public player2;
    
    event SeasonCreated(uint256 indexed seasonId, string name, uint256 jackpot);
    event SeasonCompleted(address indexed player, uint256 indexed seasonId, uint256 reward);
    event SeasonEnded(uint256 indexed seasonId, uint256 totalCompleters);
    
    function setUp() public {
        owner = address(this);
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        
        vm.deal(owner, 100 ether);
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        
        puzzleManager = new PuzzleManager();
        seasonManager = new SeasonManager();
        
        seasonManager.setPuzzleManager(address(puzzleManager));
        
        // Fund puzzle manager
        puzzleManager.fundRewardPool{value: 10 ether}();
        
        // Create test puzzles (create 10 to cover all test cases)
        for (uint256 i = 1; i <= 10; i++) {
            puzzleManager.createPuzzle(
                string(abi.encodePacked("QmTest", i)),
                keccak256(abi.encodePacked("answer", i)),
                1 ether,
                2,
                block.timestamp,
                block.timestamp + 30 days,
                "DeFi"
            );
        }
    }
    
    function testCreateSeason() public {
        string memory name = "The Genesis Mystery";
        string memory storyHash = "QmStory123";
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 30 days;
        uint256 jackpot = 10 ether;
        uint256 minPuzzles = 5;
        
        vm.expectEmit(true, true, true, true);
        emit SeasonCreated(1, name, jackpot);
        
        uint256 seasonId = seasonManager.createSeason(
            name,
            storyHash,
            startTime,
            endTime,
            jackpot,
            minPuzzles
        );
        
        assertEq(seasonId, 1);
        
        ISeasonManager.Season memory season = seasonManager.getSeason(seasonId);
        assertEq(season.id, 1);
        assertEq(season.name, name);
        assertEq(season.storyIpfsHash, storyHash);
        assertEq(season.jackpotReward, jackpot);
        assertEq(season.minPuzzlesToComplete, minPuzzles);
        assertTrue(season.active);
    }
    
    function testAddPuzzleToSeason() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            10 ether,
            3
        );
        
        seasonManager.addPuzzleToSeason(seasonId, 1);
        seasonManager.addPuzzleToSeason(seasonId, 2);
        seasonManager.addPuzzleToSeason(seasonId, 3);
        
        uint256[] memory puzzles = seasonManager.getSeasonPuzzles(seasonId);
        assertEq(puzzles.length, 3);
        assertEq(puzzles[0], 1);
        assertEq(puzzles[1], 2);
        assertEq(puzzles[2], 3);
    }
    
    function testCompleteSeasonPuzzle() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            10 ether,
            2
        );
        
        seasonManager.addPuzzleToSeason(seasonId, 1);
        seasonManager.addPuzzleToSeason(seasonId, 2);
        
        seasonManager.completeSeasonPuzzle(player1, seasonId, 1);
        seasonManager.completeSeasonPuzzle(player1, seasonId, 2);
        
        uint256[] memory progress = seasonManager.getPlayerSeasonProgress(player1, seasonId);
        assertEq(progress.length, 2);
        
        assertTrue(seasonManager.hasPlayerCompletedSeason(player1, seasonId));
    }
    
    function testClaimSeasonReward() public {
        uint256 jackpot = 5 ether;
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            jackpot,
            2
        );
        
        // Fund season
        seasonManager.fundSeasonReward{value: jackpot}(seasonId);
        
        seasonManager.addPuzzleToSeason(seasonId, 1);
        seasonManager.addPuzzleToSeason(seasonId, 2);
        
        seasonManager.completeSeasonPuzzle(player1, seasonId, 1);
        seasonManager.completeSeasonPuzzle(player1, seasonId, 2);
        
        uint256 balanceBefore = player1.balance;
        
        vm.prank(player1);
        vm.expectEmit(true, true, true, true);
        emit SeasonCompleted(player1, seasonId, jackpot);
        
        seasonManager.claimSeasonReward(seasonId);
        
        uint256 balanceAfter = player1.balance;
        assertEq(balanceAfter - balanceBefore, jackpot);
    }
    
    function testCannotClaimRewardTwice() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            5 ether,
            1
        );
        
        seasonManager.fundSeasonReward{value: 5 ether}(seasonId);
        seasonManager.addPuzzleToSeason(seasonId, 1);
        seasonManager.completeSeasonPuzzle(player1, seasonId, 1);
        
        vm.startPrank(player1);
        seasonManager.claimSeasonReward(seasonId);
        
        vm.expectRevert("SeasonManager: reward already claimed");
        seasonManager.claimSeasonReward(seasonId);
        vm.stopPrank();
    }
    
    function testGetCurrentSeason() public {
        uint256 seasonId = seasonManager.createSeason(
            "Current Season",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            10 ether,
            3
        );
        
        ISeasonManager.Season memory currentSeason = seasonManager.getCurrentSeason();
        assertEq(currentSeason.id, seasonId);
        assertEq(currentSeason.name, "Current Season");
    }
    
    function testEndSeason() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 7 days,
            10 ether,
            3
        );
        
        // Fast forward past end time
        vm.warp(block.timestamp + 8 days);
        
        vm.expectEmit(true, true, true, true);
        emit SeasonEnded(seasonId, 0);
        
        seasonManager.endSeason(seasonId);
        
        assertFalse(seasonManager.isSeasonActive(seasonId));
    }
    
    function testGetAllSeasons() public {
        seasonManager.createSeason(
            "Season 1",
            "QmStory1",
            block.timestamp,
            block.timestamp + 30 days,
            5 ether,
            3
        );
        
        seasonManager.createSeason(
            "Season 2",
            "QmStory2",
            block.timestamp,
            block.timestamp + 30 days,
            10 ether,
            5
        );
        
        ISeasonManager.Season[] memory allSeasons = seasonManager.getAllSeasons();
        assertEq(allSeasons.length, 2);
        assertEq(allSeasons[0].name, "Season 1");
        assertEq(allSeasons[1].name, "Season 2");
    }
    
    function testGetPlayerCompletionPercentage() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            10 ether,
            5
        );
        
        for (uint256 i = 1; i <= 5; i++) {
            seasonManager.addPuzzleToSeason(seasonId, i);
        }
        
        seasonManager.completeSeasonPuzzle(player1, seasonId, 1);
        seasonManager.completeSeasonPuzzle(player1, seasonId, 2);
        
        uint256 percentage = seasonManager.getPlayerCompletionPercentage(player1, seasonId);
        assertEq(percentage, 40); // 2 out of 5 = 40%
    }
    
    function testIsPlayerEligibleForReward() public {
        uint256 seasonId = seasonManager.createSeason(
            "Season 1",
            "QmStory",
            block.timestamp,
            block.timestamp + 30 days,
            5 ether,
            2
        );
        
        seasonManager.fundSeasonReward{value: 5 ether}(seasonId);
        seasonManager.addPuzzleToSeason(seasonId, 1);
        seasonManager.addPuzzleToSeason(seasonId, 2);
        
        assertFalse(seasonManager.isPlayerEligibleForReward(player1, seasonId));
        
        seasonManager.completeSeasonPuzzle(player1, seasonId, 1);
        seasonManager.completeSeasonPuzzle(player1, seasonId, 2);
        
        assertTrue(seasonManager.isPlayerEligibleForReward(player1, seasonId));
    }
    
    receive() external payable {}
}

