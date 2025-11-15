// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPredictionMarket {
    struct Prediction {
        uint256 id;
        uint256 puzzleId;
        address[] predictedSolvers;
        uint256 totalPool;
        uint256 endTime;
        bool resolved;
        address actualSolver;
    }

    struct Bet {
        address bettor;
        address predictedSolver;
        uint256 amount;
        bool claimed;
    }

    event PredictionCreated(uint256 indexed predictionId, uint256 indexed puzzleId);
    event BetPlaced(uint256 indexed predictionId, address indexed bettor, address indexed predictedSolver, uint256 amount);
    event PredictionResolved(uint256 indexed predictionId, address indexed winner);
    event WinningsClaimed(uint256 indexed predictionId, address indexed bettor, uint256 amount);

    function createPrediction(uint256 puzzleId, address[] memory predictedSolvers, uint256 duration) external returns (uint256);
    function placeBet(uint256 predictionId, address predictedSolver) external payable;
    function resolvePrediction(uint256 predictionId, address actualSolver) external;
    function claimWinnings(uint256 predictionId) external;
    
    function getPrediction(uint256 predictionId) external view returns (Prediction memory);
    function getPlayerBets(address player, uint256 predictionId) external view returns (Bet[] memory);
    function getActivePredictions() external view returns (uint256[] memory);
    function calculatePotentialWinnings(uint256 predictionId, address predictedSolver, uint256 betAmount) external view returns (uint256);
}

