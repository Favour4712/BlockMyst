// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ISeasonManager.sol";
import "../interfaces/IPuzzleManager.sol";

contract SeasonManager is Ownable, ReentrancyGuard, ISeasonManager {
    // State variables
    mapping(uint256 => Season) public seasons;
    mapping(uint256 => uint256[]) public seasonPuzzles;
    mapping(address => mapping(uint256 => bool)) public seasonCompleted;
    mapping(address => mapping(uint256 => uint256[]))
        public playerSeasonProgress;
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        public hasSolvedSeasonPuzzle;
    mapping(uint256 => uint256) public seasonRewards;
    mapping(uint256 => mapping(address => bool)) public hasClaimedSeasonReward;

    uint256 public currentSeasonId;

    IPuzzleManager public puzzleManager;

    Season[] private allSeasons;

    constructor() Ownable(msg.sender) {}

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "SeasonManager: zero address");
        puzzleManager = IPuzzleManager(_puzzleManager);
    }

    // Write Functions
    function createSeason(
        string memory name,
        string memory storyIpfsHash,
        uint256 startTime,
        uint256 endTime,
        uint256 jackpotReward,
        uint256 minPuzzlesToComplete
    ) external override onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "SeasonManager: empty name");
        require(startTime < endTime, "SeasonManager: invalid time range");
        require(endTime > block.timestamp, "SeasonManager: end time in past");
        require(minPuzzlesToComplete > 0, "SeasonManager: invalid min puzzles");

        currentSeasonId++;
        uint256 seasonId = currentSeasonId;

        Season memory newSeason = Season({
            id: seasonId,
            name: name,
            storyIpfsHash: storyIpfsHash,
            startTime: startTime,
            endTime: endTime,
            totalPuzzles: 0,
            jackpotReward: jackpotReward,
            completionCount: 0,
            active: true,
            minPuzzlesToComplete: minPuzzlesToComplete
        });

        seasons[seasonId] = newSeason;
        seasonRewards[seasonId] = jackpotReward;
        allSeasons.push(newSeason);

        emit SeasonCreated(seasonId, name, jackpotReward);
        return seasonId;
    }

    function addPuzzleToSeason(
        uint256 seasonId,
        uint256 puzzleId
    ) external override onlyOwner {
        Season storage season = seasons[seasonId];
        require(season.active, "SeasonManager: season not active");
        require(
            block.timestamp < season.endTime,
            "SeasonManager: season ended"
        );

        // Verify puzzle exists if puzzleManager is set
        if (address(puzzleManager) != address(0)) {
            IPuzzleManager.Puzzle memory puzzle = puzzleManager.getPuzzle(
                puzzleId
            );
            require(puzzle.id > 0, "SeasonManager: puzzle does not exist");
        }

        seasonPuzzles[seasonId].push(puzzleId);
        season.totalPuzzles++;
    }

    function completeSeasonPuzzle(
        address player,
        uint256 seasonId,
        uint256 puzzleId
    ) external override {
        require(
            msg.sender == address(puzzleManager) || msg.sender == owner(),
            "SeasonManager: unauthorized"
        );

        Season storage season = seasons[seasonId];
        require(season.active, "SeasonManager: season not active");

        // Check if puzzle is part of season
        bool puzzleInSeason = false;
        for (uint256 i = 0; i < seasonPuzzles[seasonId].length; i++) {
            if (seasonPuzzles[seasonId][i] == puzzleId) {
                puzzleInSeason = true;
                break;
            }
        }
        require(puzzleInSeason, "SeasonManager: puzzle not in season");

        // Check if already completed by player
        require(
            !hasSolvedSeasonPuzzle[player][seasonId][puzzleId],
            "SeasonManager: already completed"
        );

        hasSolvedSeasonPuzzle[player][seasonId][puzzleId] = true;
        playerSeasonProgress[player][seasonId].push(puzzleId);

        // Check if player completed the season
        if (
            playerSeasonProgress[player][seasonId].length >=
            season.minPuzzlesToComplete &&
            !seasonCompleted[player][seasonId]
        ) {
            seasonCompleted[player][seasonId] = true;
            season.completionCount++;
        }
    }

    function claimSeasonReward(
        uint256 seasonId
    ) external override nonReentrant {
        Season storage season = seasons[seasonId];
        require(
            seasonCompleted[msg.sender][seasonId],
            "SeasonManager: season not completed"
        );
        require(
            !hasClaimedSeasonReward[seasonId][msg.sender],
            "SeasonManager: reward already claimed"
        );
        require(
            seasonRewards[seasonId] > 0,
            "SeasonManager: no reward available"
        );
        require(
            address(this).balance >= season.jackpotReward,
            "SeasonManager: insufficient balance"
        );

        uint256 reward = season.jackpotReward;
        hasClaimedSeasonReward[seasonId][msg.sender] = true;
        seasonRewards[seasonId] -= reward; // Deduct from available rewards

        // Transfer reward
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "SeasonManager: transfer failed");

        emit SeasonCompleted(msg.sender, seasonId, reward);
    }

    function endSeason(uint256 seasonId) external override onlyOwner {
        Season storage season = seasons[seasonId];
        require(season.active, "SeasonManager: season not active");
        require(
            block.timestamp >= season.endTime,
            "SeasonManager: season not ended"
        );

        season.active = false;

        emit SeasonEnded(seasonId, season.completionCount);
    }

    function fundSeasonReward(uint256 seasonId) external payable onlyOwner {
        require(
            seasons[seasonId].id > 0,
            "SeasonManager: season does not exist"
        );
        seasonRewards[seasonId] += msg.value;
        // Note: jackpotReward is set during creation and represents the reward amount per player
        // We don't modify it here, just track the total funded amount in seasonRewards
    }

    // Read Functions
    function getCurrentSeason() external view override returns (Season memory) {
        if (currentSeasonId > 0 && seasons[currentSeasonId].active) {
            return seasons[currentSeasonId];
        }
        return Season(0, "", "", 0, 0, 0, 0, 0, false, 0);
    }

    function getSeasonPuzzles(
        uint256 seasonId
    ) external view override returns (uint256[] memory) {
        return seasonPuzzles[seasonId];
    }

    function getPlayerSeasonProgress(
        address player,
        uint256 seasonId
    ) external view override returns (uint256[] memory) {
        return playerSeasonProgress[player][seasonId];
    }

    function hasPlayerCompletedSeason(
        address player,
        uint256 seasonId
    ) external view override returns (bool) {
        return seasonCompleted[player][seasonId];
    }

    function getSeasonCompletionCount(
        uint256 seasonId
    ) external view override returns (uint256) {
        return seasons[seasonId].completionCount;
    }

    function getAllSeasons() external view override returns (Season[] memory) {
        return allSeasons;
    }

    function getSeasonReward(
        uint256 seasonId
    ) external view override returns (uint256) {
        return seasonRewards[seasonId];
    }

    function getSeasonStory(
        uint256 seasonId
    ) external view override returns (string memory) {
        return seasons[seasonId].storyIpfsHash;
    }

    function isSeasonActive(
        uint256 seasonId
    ) external view override returns (bool) {
        Season memory season = seasons[seasonId];
        return
            season.active &&
            block.timestamp >= season.startTime &&
            block.timestamp < season.endTime;
    }

    function getPlayerCompletionPercentage(
        address player,
        uint256 seasonId
    ) external view returns (uint256) {
        Season memory season = seasons[seasonId];
        if (season.totalPuzzles == 0) return 0;

        uint256 completed = playerSeasonProgress[player][seasonId].length;
        return (completed * 100) / season.totalPuzzles;
    }

    function getSeason(uint256 seasonId) external view returns (Season memory) {
        return seasons[seasonId];
    }

    function isPlayerEligibleForReward(
        address player,
        uint256 seasonId
    ) external view returns (bool) {
        return
            seasonCompleted[player][seasonId] &&
            !hasClaimedSeasonReward[seasonId][player] &&
            seasonRewards[seasonId] > 0;
    }

    // Receive function
    receive() external payable {}
}
