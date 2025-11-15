// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPuzzleManager {
    struct Puzzle {
        uint256 id;
        string ipfsHash;
        bytes32 answerHash;
        uint256 reward;
        uint256 difficulty;
        uint256 startTime;
        uint256 endTime;
        uint256 solveCount;
        bool active;
        string category;
    }

    event PuzzleCreated(
        uint256 indexed puzzleId,
        uint256 difficulty,
        uint256 reward
    );
    event PuzzleSolved(
        address indexed player,
        uint256 indexed puzzleId,
        uint256 reward
    );
    event RewardClaimed(address indexed player, uint256 amount, uint256 nftId);
    event StreakAchieved(address indexed player, uint256 streak, uint256 bonus);
    event LeaderboardUpdated(address indexed player, uint256 newScore);
    event UsernameRegistered(address indexed player, string username);

    function createPuzzle(
        string memory ipfsHash,
        bytes32 answerHash,
        uint256 reward,
        uint256 difficulty,
        uint256 startTime,
        uint256 endTime,
        string memory category
    ) external returns (uint256);

    function submitAnswer(
        uint256 puzzleId,
        string memory answer
    ) external returns (bool);

    function claimReward(uint256 puzzleId) external;

    function updatePuzzle(
        uint256 puzzleId,
        string memory ipfsHash,
        uint256 endTime
    ) external;

    function deactivatePuzzle(uint256 puzzleId) external;

    function fundRewardPool() external payable;

    function withdrawRewardPool(uint256 amount) external;

    function getPuzzle(uint256 puzzleId) external view returns (Puzzle memory);

    function getActivePuzzles() external view returns (uint256[] memory);

    function getPuzzlesByDifficulty(
        uint256 difficulty
    ) external view returns (uint256[] memory);

    function getPuzzlesByCategory(
        string memory category
    ) external view returns (uint256[] memory);

    function hasPlayerSolved(
        address player,
        uint256 puzzleId
    ) external view returns (bool);

    function getPlayerStats(
        address player
    )
        external
        view
        returns (uint256 score, uint256 streak, uint256 totalSolved);

    function getPlayerSolvedPuzzles(
        address player
    ) external view returns (uint256[] memory);

    function getCurrentStreak(address player) external view returns (uint256);

    function getRewardAmount(uint256 puzzleId) external view returns (uint256);

    function getTotalSolvers(uint256 puzzleId) external view returns (uint256);

    function isPuzzleActive(uint256 puzzleId) external view returns (bool);

    function getTimeRemaining(uint256 puzzleId) external view returns (uint256);

    function getRewardPoolBalance() external view returns (uint256);

    function getDailyPuzzle() external view returns (Puzzle memory);

    // Username functions
    function registerUsername(string memory username) external;

    function getUsername(address player) external view returns (string memory);

    function getAddressByUsername(
        string memory username
    ) external view returns (address);

    function isUsernameAvailable(
        string memory username
    ) external view returns (bool);
}
