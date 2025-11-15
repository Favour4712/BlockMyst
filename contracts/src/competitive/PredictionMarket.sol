// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPredictionMarket.sol";

contract PredictionMarket is Ownable, ReentrancyGuard, IPredictionMarket {
    // State variables
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => mapping(address => Bet[])) public playerBets;
    mapping(uint256 => mapping(address => uint256)) public solverPools; // predictionId => solver => total bet on them

    uint256 public currentPredictionId;
    uint256 public platformFeePercentage = 5; // 5% platform fee
    uint256 public constant MIN_BET = 0.01 ether;

    address public puzzleManager;

    constructor() Ownable(msg.sender) {}

    modifier onlyPuzzleManager() {
        require(
            msg.sender == puzzleManager,
            "PredictionMarket: not puzzle manager"
        );
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "PredictionMarket: zero address");
        puzzleManager = _puzzleManager;
    }

    function setPlatformFee(uint256 percentage) external onlyOwner {
        require(percentage <= 10, "PredictionMarket: fee too high");
        platformFeePercentage = percentage;
    }

    // Write Functions
    function createPrediction(
        uint256 puzzleId,
        address[] memory predictedSolvers,
        uint256 duration
    ) external override onlyOwner returns (uint256) {
        require(predictedSolvers.length > 0, "PredictionMarket: no solvers");
        require(duration > 0, "PredictionMarket: invalid duration");

        currentPredictionId++;
        uint256 predictionId = currentPredictionId;

        predictions[predictionId] = Prediction({
            id: predictionId,
            puzzleId: puzzleId,
            predictedSolvers: predictedSolvers,
            totalPool: 0,
            endTime: block.timestamp + duration,
            resolved: false,
            actualSolver: address(0)
        });

        emit PredictionCreated(predictionId, puzzleId);
        return predictionId;
    }

    function placeBet(
        uint256 predictionId,
        address predictedSolver
    ) external payable override nonReentrant {
        Prediction storage prediction = predictions[predictionId];
        require(
            prediction.id > 0,
            "PredictionMarket: prediction does not exist"
        );
        require(
            block.timestamp < prediction.endTime,
            "PredictionMarket: prediction ended"
        );
        require(!prediction.resolved, "PredictionMarket: prediction resolved");
        require(msg.value >= MIN_BET, "PredictionMarket: bet too small");
        require(
            _isSolverInList(prediction.predictedSolvers, predictedSolver),
            "PredictionMarket: solver not in list"
        );

        playerBets[predictionId][msg.sender].push(
            Bet({
                bettor: msg.sender,
                predictedSolver: predictedSolver,
                amount: msg.value,
                claimed: false
            })
        );

        prediction.totalPool += msg.value;
        solverPools[predictionId][predictedSolver] += msg.value;

        emit BetPlaced(predictionId, msg.sender, predictedSolver, msg.value);
    }

    function resolvePrediction(
        uint256 predictionId,
        address actualSolver
    ) external override onlyPuzzleManager {
        Prediction storage prediction = predictions[predictionId];

        // If prediction doesn't exist for this puzzleId, just return (no revert)
        if (prediction.id == 0) {
            return;
        }

        // If already resolved, just return (no revert)
        if (prediction.resolved) {
            return;
        }

        // Check if we should resolve
        require(
            block.timestamp >= prediction.endTime || actualSolver != address(0),
            "PredictionMarket: not ready to resolve"
        );

        prediction.resolved = true;
        prediction.actualSolver = actualSolver;

        emit PredictionResolved(predictionId, actualSolver);
    }

    function claimWinnings(
        uint256 predictionId
    ) external override nonReentrant {
        Prediction memory prediction = predictions[predictionId];
        require(prediction.resolved, "PredictionMarket: not resolved");
        require(
            prediction.actualSolver != address(0),
            "PredictionMarket: no winner"
        );

        Bet[] storage bets = playerBets[predictionId][msg.sender];
        require(bets.length > 0, "PredictionMarket: no bets");

        uint256 totalWinnings = 0;
        uint256 playerWinningBets = 0;

        for (uint256 i = 0; i < bets.length; i++) {
            if (
                !bets[i].claimed &&
                bets[i].predictedSolver == prediction.actualSolver
            ) {
                uint256 winnings = _calculateWinnings(
                    predictionId,
                    bets[i].amount,
                    prediction.actualSolver,
                    prediction.totalPool
                );
                totalWinnings += winnings;
                playerWinningBets += bets[i].amount;
                bets[i].claimed = true;
            }
        }

        require(totalWinnings > 0, "PredictionMarket: no winnings");

        (bool success, ) = msg.sender.call{value: totalWinnings}("");
        require(success, "PredictionMarket: transfer failed");

        emit WinningsClaimed(predictionId, msg.sender, totalWinnings);
    }

    // Read Functions
    function getPrediction(
        uint256 predictionId
    ) external view override returns (Prediction memory) {
        return predictions[predictionId];
    }

    function getPlayerBets(
        address player,
        uint256 predictionId
    ) external view override returns (Bet[] memory) {
        return playerBets[predictionId][player];
    }

    function getActivePredictions()
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentPredictionId; i++) {
            if (
                !predictions[i].resolved &&
                block.timestamp < predictions[i].endTime
            ) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPredictionId; i++) {
            if (
                !predictions[i].resolved &&
                block.timestamp < predictions[i].endTime
            ) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    function calculatePotentialWinnings(
        uint256 predictionId,
        address predictedSolver,
        uint256 betAmount
    ) external view override returns (uint256) {
        Prediction memory prediction = predictions[predictionId];
        uint256 totalOnSolver = solverPools[predictionId][predictedSolver] +
            betAmount;
        uint256 potentialPool = prediction.totalPool + betAmount;

        if (totalOnSolver == 0) return 0;

        uint256 winnerShare = (betAmount * potentialPool) / totalOnSolver;
        uint256 platformFee = (winnerShare * platformFeePercentage) / 100;

        return winnerShare - platformFee;
    }

    function getSolverOdds(
        uint256 predictionId,
        address solver
    ) external view returns (uint256) {
        Prediction memory prediction = predictions[predictionId];
        uint256 totalOnSolver = solverPools[predictionId][solver];

        if (prediction.totalPool == 0 || totalOnSolver == 0) return 0;

        return (prediction.totalPool * 100) / totalOnSolver; // Returns odds as percentage
    }

    // Internal Functions
    function _isSolverInList(
        address[] memory solvers,
        address solver
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < solvers.length; i++) {
            if (solvers[i] == solver) {
                return true;
            }
        }
        return false;
    }

    function _calculateWinnings(
        uint256 predictionId,
        uint256 betAmount,
        address winningSolver,
        uint256 totalPool
    ) internal view returns (uint256) {
        uint256 totalOnWinner = solverPools[predictionId][winningSolver];

        if (totalOnWinner == 0) return 0;

        // Winner gets proportional share of total pool
        uint256 winnings = (betAmount * totalPool) / totalOnWinner;

        // Subtract platform fee
        uint256 platformFee = (winnings * platformFeePercentage) / 100;

        return winnings - platformFee;
    }

    // Receive function
    receive() external payable {}
}
