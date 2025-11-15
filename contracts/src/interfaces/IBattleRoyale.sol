// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBattleRoyale {
    struct Battle {
        uint256 id;
        uint256 startTime;
        uint256 prizePool;
        uint256[] puzzleIds;
        uint256 currentRound;
        uint256 maxRounds;
        bool active;
        bool completed;
    }

    struct BattlePlayer {
        address playerAddress;
        uint256 score;
        uint256 roundsCompleted;
        bool eliminated;
        uint256 eliminatedRound;
    }

    event BattleCreated(
        uint256 indexed battleId,
        uint256 prizePool,
        uint256 maxRounds
    );
    event PlayerJoined(uint256 indexed battleId, address indexed player);
    event RoundCompleted(
        uint256 indexed battleId,
        uint256 round,
        uint256 playersEliminated
    );
    event PlayerEliminated(
        uint256 indexed battleId,
        address indexed player,
        uint256 round
    );
    event BattleCompleted(uint256 indexed battleId, address[] winners);
    event PrizeDistributed(
        uint256 indexed battleId,
        address indexed player,
        uint256 amount
    );

    function createBattle(
        uint256 prizePool,
        uint256[] memory puzzleIds,
        uint256 maxRounds
    ) external returns (uint256);

    function joinBattle(uint256 battleId) external payable;

    function submitBattleAnswer(
        uint256 battleId,
        uint256 puzzleId,
        string memory answer
    ) external;

    function endRound(uint256 battleId) external;

    function completeBattle(uint256 battleId) external;

    function claimBattlePrize(uint256 battleId) external;

    function getBattle(uint256 battleId) external view returns (Battle memory);

    function getBattlePlayers(
        uint256 battleId
    ) external view returns (address[] memory);

    function getPlayerBattleStats(
        uint256 battleId,
        address player
    ) external view returns (BattlePlayer memory);

    function isPlayerInBattle(
        uint256 battleId,
        address player
    ) external view returns (bool);

    function getActiveBattle() external view returns (Battle memory);
}

