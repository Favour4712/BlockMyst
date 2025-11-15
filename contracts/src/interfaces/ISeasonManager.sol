// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISeasonManager {
    struct Season {
        uint256 id;
        string name;
        string storyIpfsHash;
        uint256 startTime;
        uint256 endTime;
        uint256 totalPuzzles;
        uint256 jackpotReward;
        uint256 completionCount;
        bool active;
        uint256 minPuzzlesToComplete;
    }

    event SeasonCreated(uint256 indexed seasonId, string name, uint256 jackpot);
    event SeasonCompleted(address indexed player, uint256 indexed seasonId, uint256 reward);
    event SeasonEnded(uint256 indexed seasonId, uint256 totalCompleters);

    function createSeason(
        string memory name,
        string memory storyIpfsHash,
        uint256 startTime,
        uint256 endTime,
        uint256 jackpotReward,
        uint256 minPuzzlesToComplete
    ) external returns (uint256);

    function addPuzzleToSeason(uint256 seasonId, uint256 puzzleId) external;
    function completeSeasonPuzzle(address player, uint256 seasonId, uint256 puzzleId) external;
    function claimSeasonReward(uint256 seasonId) external;
    function endSeason(uint256 seasonId) external;

    function getCurrentSeason() external view returns (Season memory);
    function getSeasonPuzzles(uint256 seasonId) external view returns (uint256[] memory);
    function getPlayerSeasonProgress(address player, uint256 seasonId) external view returns (uint256[] memory);
    function hasPlayerCompletedSeason(address player, uint256 seasonId) external view returns (bool);
    function getSeasonCompletionCount(uint256 seasonId) external view returns (uint256);
    function getAllSeasons() external view returns (Season[] memory);
    function getSeasonReward(uint256 seasonId) external view returns (uint256);
    function getSeasonStory(uint256 seasonId) external view returns (string memory);
    function isSeasonActive(uint256 seasonId) external view returns (bool);
}

