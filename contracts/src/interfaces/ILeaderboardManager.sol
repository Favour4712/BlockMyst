// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILeaderboardManager {
    struct PlayerStats {
        uint256 totalSolved;
        uint256 totalPoints;
        uint256 currentStreak;
        uint256 longestStreak;
        uint256 averageSolveTime;
        uint256 fastestSolve;
        uint256 lastActive;
        uint256 rank;
        uint256 totalEarned;
    }

    struct Tournament {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 prizePool;
        uint256[] puzzleIds;
        bool active;
        bool distributed;
        uint256 participantCount;
    }

    event TournamentCreated(uint256 indexed tournamentId, uint256 prizePool);
    event PlayerJoinedTournament(address indexed player, uint256 indexed tournamentId);
    event TournamentEnded(uint256 indexed tournamentId, address[] winners);
    event LeaderboardUpdated(address[] topPlayers);
    event RewardDistributed(address indexed player, uint256 amount, uint256 indexed tournamentId);

    function createTournament(
        uint256 startTime,
        uint256 endTime,
        uint256 prizePool,
        uint256[] memory puzzleIds
    ) external returns (uint256);

    function joinTournament(uint256 tournamentId) external;
    function endTournament(uint256 tournamentId) external;
    function updatePlayerStats(
        address player,
        uint256 points,
        uint256 solveTime,
        uint256 earned
    ) external;
    function updateLeaderboard() external;
    function claimTournamentReward(uint256 tournamentId) external;

    function getGlobalLeaderboard(uint256 limit) external view returns (address[] memory);
    function getWeeklyLeaderboard(uint256 limit) external view returns (address[] memory);
    function getMonthlyLeaderboard(uint256 limit) external view returns (address[] memory);
    function getPlayerRank(address player) external view returns (uint256);
    function getPlayerStats(address player) external view returns (PlayerStats memory);
    function getTournamentDetails(uint256 tournamentId) external view returns (Tournament memory);
    function getActiveTournament() external view returns (Tournament memory);
    function getTournamentLeaderboard(uint256 tournamentId, uint256 limit) external view returns (address[] memory);
    function getTournamentParticipants(uint256 tournamentId) external view returns (address[] memory);
    function getPlayerTournamentScore(address player, uint256 tournamentId) external view returns (uint256);
    function isPlayerInTournament(address player, uint256 tournamentId) external view returns (bool);
    function getPlayerAverageSolveTime(address player) external view returns (uint256);
    function getPlayerFastestSolve(address player) external view returns (uint256);
    function getTopStreakHolders(uint256 limit) external view returns (address[] memory);
    function addPlayerToLeaderboard(address player) external;
}

