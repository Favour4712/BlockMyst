// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ILeaderboardManager.sol";

contract LeaderboardManager is Ownable, ReentrancyGuard, ILeaderboardManager {
    // State variables
    mapping(uint256 => Tournament) public tournaments;
    mapping(address => PlayerStats) public playerStats;
    address[] public topPlayers;
    mapping(uint256 => address[]) public tournamentParticipants;
    mapping(uint256 => mapping(address => uint256)) public tournamentScores;
    mapping(uint256 => mapping(address => bool)) public hasJoinedTournament;
    mapping(uint256 => mapping(address => bool)) public hasClaimedTournamentReward;
    
    uint256 public currentTournamentId;
    uint256 public weeklyPrizePool;
    uint256 public monthlyPrizePool;
    
    // Tracking weekly/monthly players
    mapping(uint256 => mapping(address => uint256)) public weeklyScores; // week number => player => score
    mapping(uint256 => mapping(address => uint256)) public monthlyScores; // month number => player => score
    mapping(uint256 => address[]) public weeklyPlayers; // week number => players
    mapping(uint256 => address[]) public monthlyPlayers; // month number => players
    
    address public puzzleManager;
    
    // Constants
    uint256 private constant WEEK_IN_SECONDS = 7 days;
    uint256 private constant MONTH_IN_SECONDS = 30 days;

    constructor() Ownable(msg.sender) {}

    // Modifiers
    modifier onlyPuzzleManager() {
        require(msg.sender == puzzleManager, "LeaderboardManager: caller is not PuzzleManager");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "LeaderboardManager: zero address");
        puzzleManager = _puzzleManager;
    }

    function fundWeeklyPrizePool() external payable onlyOwner {
        weeklyPrizePool += msg.value;
    }

    function fundMonthlyPrizePool() external payable onlyOwner {
        monthlyPrizePool += msg.value;
    }

    // Write Functions
    function createTournament(
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool,
        uint256[] memory puzzleIds
    ) external override onlyOwner returns (uint256) {
        require(startTime < endTime, "LeaderboardManager: invalid time range");
        require(endTime > block.timestamp, "LeaderboardManager: end time in past");

        currentTournamentId++;
        uint256 tournamentId = currentTournamentId;

        tournaments[tournamentId] = Tournament({
            id: tournamentId,
            startTime: startTime,
            endTime: endTime,
            prizePool: prizePool,
            puzzleIds: puzzleIds,
            active: true,
            distributed: false,
            participantCount: 0
        });

        emit TournamentCreated(tournamentId, prizePool);
        return tournamentId;
    }

    function joinTournament(uint256 tournamentId) external override {
        Tournament storage tournament = tournaments[tournamentId];
        require(tournament.active, "LeaderboardManager: tournament not active");
        require(block.timestamp >= tournament.startTime, "LeaderboardManager: tournament not started");
        require(block.timestamp < tournament.endTime, "LeaderboardManager: tournament ended");
        require(!hasJoinedTournament[tournamentId][msg.sender], "LeaderboardManager: already joined");

        hasJoinedTournament[tournamentId][msg.sender] = true;
        tournamentParticipants[tournamentId].push(msg.sender);
        tournament.participantCount++;

        emit PlayerJoinedTournament(msg.sender, tournamentId);
    }

    function endTournament(uint256 tournamentId) external override onlyOwner {
        Tournament storage tournament = tournaments[tournamentId];
        require(tournament.active, "LeaderboardManager: tournament not active");
        require(block.timestamp >= tournament.endTime, "LeaderboardManager: tournament not ended");

        tournament.active = false;
        tournament.distributed = true;

        // Get top 10 winners
        address[] memory winners = getTournamentLeaderboard(tournamentId, 10);
        
        emit TournamentEnded(tournamentId, winners);
    }

    function updatePlayerStats(
        address player,
        uint256 points,
        uint256 solveTime,
        uint256 earned
    ) external override onlyPuzzleManager {
        PlayerStats storage stats = playerStats[player];
        
        stats.totalSolved++;
        stats.totalPoints += points;
        stats.totalEarned += earned;
        stats.lastActive = block.timestamp;

        // Update solve time statistics
        if (stats.totalSolved == 1) {
            stats.averageSolveTime = solveTime;
            stats.fastestSolve = solveTime;
        } else {
            stats.averageSolveTime = (stats.averageSolveTime * (stats.totalSolved - 1) + solveTime) / stats.totalSolved;
            if (solveTime < stats.fastestSolve || stats.fastestSolve == 0) {
                stats.fastestSolve = solveTime;
            }
        }

        // Update weekly/monthly tracking
        uint256 currentWeek = block.timestamp / WEEK_IN_SECONDS;
        uint256 currentMonth = block.timestamp / MONTH_IN_SECONDS;
        
        if (weeklyScores[currentWeek][player] == 0) {
            weeklyPlayers[currentWeek].push(player);
        }
        weeklyScores[currentWeek][player] += points;
        
        if (monthlyScores[currentMonth][player] == 0) {
            monthlyPlayers[currentMonth].push(player);
        }
        monthlyScores[currentMonth][player] += points;

        // Update tournament scores if in active tournament
        if (currentTournamentId > 0 && tournaments[currentTournamentId].active) {
            if (hasJoinedTournament[currentTournamentId][player]) {
                tournamentScores[currentTournamentId][player] += points;
            }
        }
    }

    function updateLeaderboard() external override {
        // Simple implementation - could be optimized with more sophisticated sorting
        // For production, consider using off-chain sorting and verification
        _sortTopPlayers();
        emit LeaderboardUpdated(topPlayers);
    }

    function claimTournamentReward(uint256 tournamentId) external override nonReentrant {
        Tournament storage tournament = tournaments[tournamentId];
        require(!tournament.active, "LeaderboardManager: tournament still active");
        require(tournament.distributed, "LeaderboardManager: rewards not distributed");
        require(hasJoinedTournament[tournamentId][msg.sender], "LeaderboardManager: not participant");
        require(!hasClaimedTournamentReward[tournamentId][msg.sender], "LeaderboardManager: already claimed");

        uint256 playerScore = tournamentScores[tournamentId][msg.sender];
        require(playerScore > 0, "LeaderboardManager: no score");

        // Get player's rank
        address[] memory leaderboard = getTournamentLeaderboard(tournamentId, 10);
        uint256 rank = 11; // Default to out of prizes
        for (uint256 i = 0; i < leaderboard.length && i < 10; i++) {
            if (leaderboard[i] == msg.sender) {
                rank = i + 1;
                break;
            }
        }

        require(rank <= 10, "LeaderboardManager: not in top 10");

        // Calculate reward based on rank
        uint256 reward = _calculateTournamentReward(tournament.prizePool, rank);
        require(reward > 0, "LeaderboardManager: no reward");

        hasClaimedTournamentReward[tournamentId][msg.sender] = true;

        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "LeaderboardManager: transfer failed");

        emit RewardDistributed(msg.sender, reward, tournamentId);
    }

    // Read Functions
    function getGlobalLeaderboard(uint256 limit) external view override returns (address[] memory) {
        uint256 length = topPlayers.length < limit ? topPlayers.length : limit;
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = topPlayers[i];
        }
        return result;
    }

    function getWeeklyLeaderboard(uint256 limit) external view override returns (address[] memory) {
        uint256 currentWeek = block.timestamp / WEEK_IN_SECONDS;
        address[] memory players = weeklyPlayers[currentWeek];
        
        // Sort players by weekly score
        address[] memory sorted = _sortPlayersByScore(players, currentWeek, true);
        
        uint256 length = sorted.length < limit ? sorted.length : limit;
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = sorted[i];
        }
        return result;
    }

    function getMonthlyLeaderboard(uint256 limit) external view override returns (address[] memory) {
        uint256 currentMonth = block.timestamp / MONTH_IN_SECONDS;
        address[] memory players = monthlyPlayers[currentMonth];
        
        // Sort players by monthly score
        address[] memory sorted = _sortPlayersByScore(players, currentMonth, false);
        
        uint256 length = sorted.length < limit ? sorted.length : limit;
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = sorted[i];
        }
        return result;
    }

    function getPlayerRank(address player) external view override returns (uint256) {
        return playerStats[player].rank;
    }

    function getPlayerStats(address player) external view override returns (PlayerStats memory) {
        return playerStats[player];
    }

    function getTournamentDetails(uint256 tournamentId) external view override returns (Tournament memory) {
        return tournaments[tournamentId];
    }

    function getActiveTournament() external view override returns (Tournament memory) {
        if (currentTournamentId > 0 && tournaments[currentTournamentId].active) {
            return tournaments[currentTournamentId];
        }
        return Tournament(0, 0, 0, 0, new uint256[](0), false, false, 0);
    }

    function getTournamentLeaderboard(uint256 tournamentId, uint256 limit) 
        public 
        view 
        override 
        returns (address[] memory) 
    {
        address[] memory participants = tournamentParticipants[tournamentId];
        address[] memory sorted = _sortTournamentParticipants(tournamentId, participants);
        
        uint256 length = sorted.length < limit ? sorted.length : limit;
        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = sorted[i];
        }
        return result;
    }

    function getTournamentParticipants(uint256 tournamentId) 
        external 
        view 
        override 
        returns (address[] memory) 
    {
        return tournamentParticipants[tournamentId];
    }

    function getPlayerTournamentScore(address player, uint256 tournamentId) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return tournamentScores[tournamentId][player];
    }

    function isPlayerInTournament(address player, uint256 tournamentId) 
        external 
        view 
        override 
        returns (bool) 
    {
        return hasJoinedTournament[tournamentId][player];
    }

    function getPlayerAverageSolveTime(address player) external view override returns (uint256) {
        return playerStats[player].averageSolveTime;
    }

    function getPlayerFastestSolve(address player) external view override returns (uint256) {
        return playerStats[player].fastestSolve;
    }

    function getTopStreakHolders(uint256 limit) external view override returns (address[] memory) {
        // For simplicity, iterate through known players
        // In production, maintain a separate sorted array
        address[] memory result = new address[](limit);
        uint256[] memory streaks = new uint256[](limit);
        
        for (uint256 i = 0; i < topPlayers.length && i < 100; i++) {
            address player = topPlayers[i];
            uint256 streak = playerStats[player].currentStreak;
            
            for (uint256 j = 0; j < limit; j++) {
                if (streak > streaks[j]) {
                    // Shift elements down
                    for (uint256 k = limit - 1; k > j; k--) {
                        result[k] = result[k - 1];
                        streaks[k] = streaks[k - 1];
                    }
                    result[j] = player;
                    streaks[j] = streak;
                    break;
                }
            }
        }
        
        return result;
    }

    // Internal Functions
    function _sortTopPlayers() internal {
        // Simple bubble sort for demonstration
        // In production, use more efficient sorting or off-chain computation
        for (uint256 i = 0; i < topPlayers.length && i < 100; i++) {
            for (uint256 j = i + 1; j < topPlayers.length && j < 100; j++) {
                if (playerStats[topPlayers[j]].totalPoints > playerStats[topPlayers[i]].totalPoints) {
                    address temp = topPlayers[i];
                    topPlayers[i] = topPlayers[j];
                    topPlayers[j] = temp;
                }
            }
        }
        
        // Update ranks
        for (uint256 i = 0; i < topPlayers.length && i < 100; i++) {
            playerStats[topPlayers[i]].rank = i + 1;
        }
    }

    function _sortPlayersByScore(address[] memory players, uint256 period, bool isWeekly) 
        internal 
        view 
        returns (address[] memory) 
    {
        address[] memory sorted = new address[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            sorted[i] = players[i];
        }
        
        // Bubble sort
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = i + 1; j < sorted.length; j++) {
                uint256 scoreI = isWeekly ? weeklyScores[period][sorted[i]] : monthlyScores[period][sorted[i]];
                uint256 scoreJ = isWeekly ? weeklyScores[period][sorted[j]] : monthlyScores[period][sorted[j]];
                
                if (scoreJ > scoreI) {
                    address temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }
        
        return sorted;
    }

    function _sortTournamentParticipants(uint256 tournamentId, address[] memory participants) 
        internal 
        view 
        returns (address[] memory) 
    {
        address[] memory sorted = new address[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            sorted[i] = participants[i];
        }
        
        // Bubble sort by tournament score
        for (uint256 i = 0; i < sorted.length; i++) {
            for (uint256 j = i + 1; j < sorted.length; j++) {
                if (tournamentScores[tournamentId][sorted[j]] > tournamentScores[tournamentId][sorted[i]]) {
                    address temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }
        
        return sorted;
    }

    function _calculateTournamentReward(uint256 totalPrize, uint256 rank) internal pure returns (uint256) {
        // Prize distribution:
        // 1st: 30%, 2nd: 20%, 3rd: 15%, 4th: 10%, 5th: 8%
        // 6th: 7%, 7th: 5%, 8th: 3%, 9th: 1%, 10th: 1%
        
        if (rank == 1) return (totalPrize * 30) / 100;
        if (rank == 2) return (totalPrize * 20) / 100;
        if (rank == 3) return (totalPrize * 15) / 100;
        if (rank == 4) return (totalPrize * 10) / 100;
        if (rank == 5) return (totalPrize * 8) / 100;
        if (rank == 6) return (totalPrize * 7) / 100;
        if (rank == 7) return (totalPrize * 5) / 100;
        if (rank == 8) return (totalPrize * 3) / 100;
        if (rank == 9) return (totalPrize * 1) / 100;
        if (rank == 10) return (totalPrize * 1) / 100;
        
        return 0;
    }

    function addPlayerToLeaderboard(address player) external onlyPuzzleManager {
        // Check if player already in leaderboard
        bool exists = false;
        for (uint256 i = 0; i < topPlayers.length; i++) {
            if (topPlayers[i] == player) {
                exists = true;
                break;
            }
        }
        
        if (!exists) {
            topPlayers.push(player);
        }
    }

    // Receive function to accept prize pools
    receive() external payable {}
}

