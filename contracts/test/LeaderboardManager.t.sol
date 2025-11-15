// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/leaderboard/LeaderboardManager.sol";

contract LeaderboardManagerTest is Test {
    LeaderboardManager public leaderboardManager;
    
    address public owner;
    address public puzzleManager;
    address public player1;
    address public player2;
    address public player3;
    
    event TournamentCreated(uint256 indexed tournamentId, uint256 prizePool);
    event PlayerJoinedTournament(address indexed player, uint256 indexed tournamentId);
    event TournamentEnded(uint256 indexed tournamentId, address[] winners);
    
    function setUp() public {
        owner = address(this);
        puzzleManager = makeAddr("puzzleManager");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        
        vm.deal(owner, 100 ether);
        
        leaderboardManager = new LeaderboardManager();
        leaderboardManager.setPuzzleManager(puzzleManager);
    }
    
    function testUpdatePlayerStats() public {
        vm.prank(puzzleManager);
        leaderboardManager.updatePlayerStats(player1, 100, 300, 1 ether);
        
        ILeaderboardManager.PlayerStats memory stats = leaderboardManager.getPlayerStats(player1);
        assertEq(stats.totalSolved, 1);
        assertEq(stats.totalPoints, 100);
        assertEq(stats.totalEarned, 1 ether);
        assertEq(stats.averageSolveTime, 300);
        assertEq(stats.fastestSolve, 300);
    }
    
    function testUpdatePlayerStatsMultiple() public {
        vm.startPrank(puzzleManager);
        
        leaderboardManager.updatePlayerStats(player1, 100, 300, 1 ether);
        leaderboardManager.updatePlayerStats(player1, 200, 150, 2 ether);
        
        vm.stopPrank();
        
        ILeaderboardManager.PlayerStats memory stats = leaderboardManager.getPlayerStats(player1);
        assertEq(stats.totalSolved, 2);
        assertEq(stats.totalPoints, 300);
        assertEq(stats.totalEarned, 3 ether);
        assertEq(stats.fastestSolve, 150);
    }
    
    function testCreateTournament() public {
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + 7 days;
        uint256 prizePool = 10 ether;
        uint256[] memory puzzleIds = new uint256[](3);
        puzzleIds[0] = 1;
        puzzleIds[1] = 2;
        puzzleIds[2] = 3;
        
        vm.expectEmit(true, true, true, true);
        emit TournamentCreated(1, prizePool);
        
        uint256 tournamentId = leaderboardManager.createTournament(
            startTime,
            endTime,
            prizePool,
            puzzleIds
        );
        
        assertEq(tournamentId, 1);
        
        ILeaderboardManager.Tournament memory tournament = leaderboardManager.getTournamentDetails(tournamentId);
        assertEq(tournament.id, 1);
        assertEq(tournament.prizePool, prizePool);
        assertTrue(tournament.active);
        assertFalse(tournament.distributed);
    }
    
    function testJoinTournament() public {
        uint256 tournamentId = leaderboardManager.createTournament(
            block.timestamp,
            block.timestamp + 7 days,
            10 ether,
            new uint256[](0)
        );
        
        vm.prank(player1);
        vm.expectEmit(true, true, true, true);
        emit PlayerJoinedTournament(player1, tournamentId);
        
        leaderboardManager.joinTournament(tournamentId);
        
        assertTrue(leaderboardManager.isPlayerInTournament(player1, tournamentId));
        
        address[] memory participants = leaderboardManager.getTournamentParticipants(tournamentId);
        assertEq(participants.length, 1);
        assertEq(participants[0], player1);
    }
    
    function testCannotJoinTournamentTwice() public {
        uint256 tournamentId = leaderboardManager.createTournament(
            block.timestamp,
            block.timestamp + 7 days,
            10 ether,
            new uint256[](0)
        );
        
        vm.startPrank(player1);
        leaderboardManager.joinTournament(tournamentId);
        
        vm.expectRevert("LeaderboardManager: already joined");
        leaderboardManager.joinTournament(tournamentId);
        vm.stopPrank();
    }
    
    function testEndTournament() public {
        uint256 tournamentId = leaderboardManager.createTournament(
            block.timestamp,
            block.timestamp + 7 days,
            10 ether,
            new uint256[](0)
        );
        
        vm.prank(player1);
        leaderboardManager.joinTournament(tournamentId);
        
        // Fast forward to end
        vm.warp(block.timestamp + 8 days);
        
        leaderboardManager.endTournament(tournamentId);
        
        ILeaderboardManager.Tournament memory tournament = leaderboardManager.getTournamentDetails(tournamentId);
        assertFalse(tournament.active);
        assertTrue(tournament.distributed);
    }
    
    function testGetActiveTournament() public {
        uint256 tournamentId = leaderboardManager.createTournament(
            block.timestamp,
            block.timestamp + 7 days,
            10 ether,
            new uint256[](0)
        );
        
        ILeaderboardManager.Tournament memory activeTournament = leaderboardManager.getActiveTournament();
        assertEq(activeTournament.id, tournamentId);
        assertTrue(activeTournament.active);
    }
    
    function testGetPlayerRank() public {
        vm.startPrank(puzzleManager);
        
        leaderboardManager.addPlayerToLeaderboard(player1);
        leaderboardManager.updatePlayerStats(player1, 100, 300, 1 ether);
        
        leaderboardManager.addPlayerToLeaderboard(player2);
        leaderboardManager.updatePlayerStats(player2, 200, 200, 2 ether);
        
        vm.stopPrank();
        
        leaderboardManager.updateLeaderboard();
        
        // Player2 should have higher rank (lower number) due to more points
        uint256 rank1 = leaderboardManager.getPlayerRank(player1);
        uint256 rank2 = leaderboardManager.getPlayerRank(player2);
        
        assertTrue(rank2 < rank1 || rank2 == 1);
    }
    
    function testGetGlobalLeaderboard() public {
        vm.startPrank(puzzleManager);
        
        leaderboardManager.addPlayerToLeaderboard(player1);
        leaderboardManager.updatePlayerStats(player1, 100, 300, 1 ether);
        
        leaderboardManager.addPlayerToLeaderboard(player2);
        leaderboardManager.updatePlayerStats(player2, 200, 200, 2 ether);
        
        leaderboardManager.addPlayerToLeaderboard(player3);
        leaderboardManager.updatePlayerStats(player3, 150, 250, 1.5 ether);
        
        vm.stopPrank();
        
        leaderboardManager.updateLeaderboard();
        
        address[] memory topPlayers = leaderboardManager.getGlobalLeaderboard(3);
        assertEq(topPlayers.length, 3);
    }
    
    function testFundPrizePools() public {
        leaderboardManager.fundWeeklyPrizePool{value: 5 ether}();
        leaderboardManager.fundMonthlyPrizePool{value: 10 ether}();
        
        assertEq(leaderboardManager.weeklyPrizePool(), 5 ether);
        assertEq(leaderboardManager.monthlyPrizePool(), 10 ether);
    }
    
    receive() external payable {}
}

