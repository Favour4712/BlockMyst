// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IPuzzleManager.sol";
import "../interfaces/IArtifactNFT.sol";
import "../interfaces/ILeaderboardManager.sol";
import "../interfaces/IProgressionManager.sol";
import "../interfaces/IGuildManager.sol";
import "../interfaces/IAchievementManager.sol";

contract PuzzleManager is Ownable, ReentrancyGuard, Pausable, IPuzzleManager {
    // State variables
    mapping(uint256 => Puzzle) public puzzles;
    mapping(uint256 => mapping(address => bool)) public hasSolved;
    mapping(address => uint256) public playerScore;
    mapping(address => uint256) public solveStreak;
    mapping(address => uint256) public lastSolveTime;
    mapping(address => uint256) public longestStreak;
    mapping(address => uint256[]) private playerSolvedPuzzles;
    mapping(address => uint256) private solveStartTime; // Track when player started solving

    // Username registration
    mapping(address => string) public playerUsername;
    mapping(string => address) public usernameToAddress;
    mapping(address => bool) public hasRegistered;

    uint256 public currentPuzzleId;
    uint256 public rewardPool;

    IArtifactNFT public artifactNFT;
    ILeaderboardManager public leaderboardManager;

    // Difficulty multipliers for points
    mapping(uint256 => uint256) public difficultyPoints;

    // Rate limiting
    mapping(address => mapping(uint256 => uint256)) public attemptCount;
    mapping(address => mapping(uint256 => uint256)) public lastAttemptTime;
    uint256 public constant MAX_ATTEMPTS_PER_HOUR = 10;
    uint256 public constant ATTEMPT_COOLDOWN = 1 hours;

    // Daily puzzle tracking
    uint256 public dailyPuzzleStartDate;

    // Staking System
    mapping(uint256 => uint256) public puzzleStakeAmount; // puzzleId => stake required
    mapping(uint256 => mapping(address => uint256)) public playerStakes; // puzzleId => player => staked amount
    mapping(uint256 => uint256) public puzzleStakePool; // puzzleId => total staked
    uint256 public stakeMultiplier = 150; // 1.5x reward for staking

    // Hint System
    mapping(uint256 => string[]) public puzzleHints; // puzzleId => hints array
    mapping(address => mapping(uint256 => uint256)) public hintsUsed; // player => puzzleId => hints used count
    uint256 public hintCostPoints = 50; // Base cost in points
    uint256 public hintPenaltyPercent = 10; // 10% reward reduction per hint

    // Additional managers
    IProgressionManager public progressionManager;
    IGuildManager public guildManager;
    IAchievementManager public achievementManager;
    address public referralManager;
    address public predictionMarket;

    // Constants
    uint256 private constant DAY_IN_SECONDS = 1 days;
    uint256 private constant STREAK_BONUS_MULTIPLIER = 10; // 10% per streak level

    constructor() Ownable(msg.sender) {
        // Set difficulty points
        difficultyPoints[1] = 100; // Easy
        difficultyPoints[2] = 250; // Medium
        difficultyPoints[3] = 500; // Hard
        difficultyPoints[4] = 1000; // Expert

        dailyPuzzleStartDate = block.timestamp;
    }

    // Admin Functions
    function setArtifactNFT(address _artifactNFT) external onlyOwner {
        require(_artifactNFT != address(0), "PuzzleManager: zero address");
        artifactNFT = IArtifactNFT(_artifactNFT);
    }

    function setLeaderboardManager(
        address _leaderboardManager
    ) external onlyOwner {
        require(
            _leaderboardManager != address(0),
            "PuzzleManager: zero address"
        );
        leaderboardManager = ILeaderboardManager(_leaderboardManager);
    }

    function setAchievementManager(
        address _achievementManager
    ) external onlyOwner {
        require(
            _achievementManager != address(0),
            "PuzzleManager: zero address"
        );
        achievementManager = IAchievementManager(_achievementManager);
    }

    function setReferralManager(address _referralManager) external onlyOwner {
        require(_referralManager != address(0), "PuzzleManager: zero address");
        referralManager = _referralManager;
    }

    function setGuildManager(address _guildManager) external onlyOwner {
        require(_guildManager != address(0), "PuzzleManager: zero address");
        guildManager = IGuildManager(_guildManager);
    }

    function setProgressionManager(
        address _progressionManager
    ) external onlyOwner {
        require(
            _progressionManager != address(0),
            "PuzzleManager: zero address"
        );
        progressionManager = IProgressionManager(_progressionManager);
    }

    function setPredictionMarket(address _predictionMarket) external onlyOwner {
        require(_predictionMarket != address(0), "PuzzleManager: zero address");
        predictionMarket = _predictionMarket;
    }

    function setStakeMultiplier(uint256 multiplier) external onlyOwner {
        require(
            multiplier >= 100 && multiplier <= 300,
            "PuzzleManager: invalid multiplier"
        );
        stakeMultiplier = multiplier;
    }

    function setHintCost(uint256 cost) external onlyOwner {
        hintCostPoints = cost;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Write Functions
    // Username Registration
    function registerUsername(string memory username) external whenNotPaused {
        require(
            !hasRegistered[msg.sender],
            "PuzzleManager: already registered"
        );
        require(
            bytes(username).length >= 3,
            "PuzzleManager: username too short"
        );
        require(
            bytes(username).length <= 20,
            "PuzzleManager: username too long"
        );
        require(
            usernameToAddress[username] == address(0),
            "PuzzleManager: username taken"
        );
        require(
            _isValidUsername(username),
            "PuzzleManager: invalid characters"
        );

        playerUsername[msg.sender] = username;
        usernameToAddress[username] = msg.sender;
        hasRegistered[msg.sender] = true;

        emit UsernameRegistered(msg.sender, username);
    }

    function _isValidUsername(
        string memory username
    ) internal pure returns (bool) {
        bytes memory b = bytes(username);
        for (uint256 i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            // Allow: a-z, A-Z, 0-9, underscore, hyphen
            if (
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x5F) && // _
                !(char == 0x2D) // -
            ) {
                return false;
            }
        }
        return true;
    }

    function createPuzzle(
        string memory ipfsHash,
        bytes32 answerHash,
        uint256 reward,
        uint256 difficulty,
        uint256 startTime,
        uint256 endTime,
        string memory category
    ) external override onlyOwner returns (uint256) {
        require(bytes(ipfsHash).length > 0, "PuzzleManager: empty IPFS hash");
        require(answerHash != bytes32(0), "PuzzleManager: empty answer hash");
        require(
            difficulty >= 1 && difficulty <= 4,
            "PuzzleManager: invalid difficulty"
        );
        require(startTime < endTime, "PuzzleManager: invalid time range");
        require(
            reward <= rewardPool,
            "PuzzleManager: insufficient reward pool"
        );

        currentPuzzleId++;
        uint256 puzzleId = currentPuzzleId;

        puzzles[puzzleId] = Puzzle({
            id: puzzleId,
            ipfsHash: ipfsHash,
            answerHash: answerHash,
            reward: reward,
            difficulty: difficulty,
            startTime: startTime,
            endTime: endTime,
            solveCount: 0,
            active: true,
            category: category
        });

        emit PuzzleCreated(puzzleId, difficulty, reward);
        return puzzleId;
    }

    function submitAnswer(
        uint256 puzzleId,
        string memory answer
    ) external override whenNotPaused nonReentrant returns (bool) {
        Puzzle storage puzzle = puzzles[puzzleId];
        require(puzzle.active, "PuzzleManager: puzzle not active");
        require(
            block.timestamp >= puzzle.startTime,
            "PuzzleManager: puzzle not started"
        );
        require(
            block.timestamp < puzzle.endTime,
            "PuzzleManager: puzzle ended"
        );
        require(
            !hasSolved[puzzleId][msg.sender],
            "PuzzleManager: already solved"
        );

        // Rate limiting
        uint256 hoursSinceLastAttempt = (block.timestamp -
            lastAttemptTime[msg.sender][puzzleId]) / 1 hours;
        if (hoursSinceLastAttempt > 0) {
            attemptCount[msg.sender][puzzleId] = 0;
        }
        require(
            attemptCount[msg.sender][puzzleId] < MAX_ATTEMPTS_PER_HOUR,
            "PuzzleManager: too many attempts"
        );

        attemptCount[msg.sender][puzzleId]++;
        lastAttemptTime[msg.sender][puzzleId] = block.timestamp;

        // Verify answer
        bytes32 submittedHash = keccak256(abi.encodePacked(answer));
        require(
            submittedHash == puzzle.answerHash,
            "PuzzleManager: incorrect answer"
        );

        // Mark as solved
        hasSolved[puzzleId][msg.sender] = true;
        puzzle.solveCount++;
        playerSolvedPuzzles[msg.sender].push(puzzleId);

        // Calculate solve time
        uint256 solveTime = 0;
        if (solveStartTime[msg.sender] > 0) {
            solveTime = block.timestamp - solveStartTime[msg.sender];
        }
        solveStartTime[msg.sender] = 0;

        // Update streak
        _updateStreak(msg.sender);

        // Calculate points with streak bonus
        uint256 basePoints = difficultyPoints[puzzle.difficulty];
        uint256 streakBonus = (basePoints *
            solveStreak[msg.sender] *
            STREAK_BONUS_MULTIPLIER) / 100;
        uint256 totalPoints = basePoints + streakBonus;

        playerScore[msg.sender] += totalPoints;

        // Update leaderboard
        if (address(leaderboardManager) != address(0)) {
            leaderboardManager.updatePlayerStats(
                msg.sender,
                totalPoints,
                solveTime,
                puzzle.reward
            );
            leaderboardManager.addPlayerToLeaderboard(msg.sender);
        }

        // Add experience to progression system
        if (address(progressionManager) != address(0)) {
            uint256 xpAmount = basePoints; // Base XP = base points
            progressionManager.addExperience(msg.sender, xpAmount);
        }

        // Contribute points to guild if player is in one
        if (address(guildManager) != address(0)) {
            if (guildManager.isInGuild(msg.sender)) {
                guildManager.contributePoints(msg.sender, totalPoints);
            }
        }

        // Check achievements
        if (address(achievementManager) != address(0)) {
            // Check solve count achievements
            uint256 totalSolved = playerSolvedPuzzles[msg.sender].length;
            if (totalSolved == 1) {
                achievementManager.checkAndUnlock(msg.sender, "first_solve");
            } else if (totalSolved == 10) {
                achievementManager.checkAndUnlock(msg.sender, "ten_solves");
            } else if (totalSolved == 50) {
                achievementManager.checkAndUnlock(msg.sender, "fifty_solves");
            } else if (totalSolved == 100) {
                achievementManager.checkAndUnlock(msg.sender, "hundred_solves");
            }

            // Check streak achievements
            if (solveStreak[msg.sender] == 5) {
                achievementManager.checkAndUnlock(msg.sender, "five_streak");
            } else if (solveStreak[msg.sender] == 10) {
                achievementManager.checkAndUnlock(msg.sender, "ten_streak");
            }

            // Check difficulty achievements
            if (puzzle.difficulty == 4) {
                achievementManager.checkAndUnlock(msg.sender, "master_solver");
            }
        }

        emit PuzzleSolved(msg.sender, puzzleId, puzzle.reward);

        if (solveStreak[msg.sender] > 0 && solveStreak[msg.sender] % 5 == 0) {
            emit StreakAchieved(
                msg.sender,
                solveStreak[msg.sender],
                streakBonus
            );
        }

        // Notify prediction market if exists
        if (predictionMarket != address(0)) {
            (bool success, ) = predictionMarket.call(
                abi.encodeWithSignature(
                    "resolvePrediction(uint256,address)",
                    puzzleId,
                    msg.sender
                )
            );
            // Don't revert if prediction market call fails (no prediction might exist)
            success;
        }

        return true;
    }

    function claimReward(
        uint256 puzzleId
    ) external override whenNotPaused nonReentrant {
        require(
            hasSolved[puzzleId][msg.sender],
            "PuzzleManager: puzzle not solved"
        );
        Puzzle storage puzzle = puzzles[puzzleId];
        require(puzzle.reward > 0, "PuzzleManager: no reward");
        require(
            rewardPool >= puzzle.reward,
            "PuzzleManager: insufficient pool"
        );

        uint256 reward = puzzle.reward;
        puzzle.reward = 0; // Prevent re-claiming
        rewardPool -= reward;

        // Apply staking bonus
        if (playerStakes[puzzleId][msg.sender] > 0) {
            uint256 stakeBonus = (reward * (stakeMultiplier - 100)) / 100;
            reward += stakeBonus;

            // Return stake
            uint256 stake = playerStakes[puzzleId][msg.sender];
            playerStakes[puzzleId][msg.sender] = 0;
            puzzleStakePool[puzzleId] -= stake;
            reward += stake;
        }

        // Apply hint penalty
        uint256 hintsUsedCount = hintsUsed[msg.sender][puzzleId];
        if (hintsUsedCount > 0) {
            uint256 penalty = (reward * hintPenaltyPercent * hintsUsedCount) /
                100;
            reward = reward > penalty ? reward - penalty : 0;
        }

        // Mint NFT artifact
        uint256 rarity = _calculateRarity(puzzle.difficulty, puzzle.solveCount);
        uint256 nftId = 0;

        if (address(artifactNFT) != address(0)) {
            nftId = artifactNFT.mintArtifact(
                msg.sender,
                puzzleId,
                rarity,
                puzzle.category,
                puzzle.solveCount
            );
        }

        // Transfer reward
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "PuzzleManager: transfer failed");

        // Pay referral reward if applicable
        if (referralManager != address(0)) {
            // Referral manager will handle payment
            (bool refSuccess, ) = referralManager.call{
                value: (reward * 5) / 100
            }(
                abi.encodeWithSignature(
                    "payReferralReward(address,uint256)",
                    msg.sender,
                    reward
                )
            );
            // Don't revert if referral fails
            refSuccess;
        }

        emit RewardClaimed(msg.sender, reward, nftId);
        emit LeaderboardUpdated(msg.sender, playerScore[msg.sender]);
    }

    function updatePuzzle(
        uint256 puzzleId,
        string memory ipfsHash,
        uint256 endTime
    ) external override onlyOwner {
        Puzzle storage puzzle = puzzles[puzzleId];
        require(puzzle.active, "PuzzleManager: puzzle not active");

        if (bytes(ipfsHash).length > 0) {
            puzzle.ipfsHash = ipfsHash;
        }

        if (endTime > block.timestamp && endTime > puzzle.startTime) {
            puzzle.endTime = endTime;
        }
    }

    function deactivatePuzzle(uint256 puzzleId) external override onlyOwner {
        puzzles[puzzleId].active = false;
    }

    function fundRewardPool() external payable override {
        require(msg.value > 0, "PuzzleManager: zero value");
        rewardPool += msg.value;
    }

    function withdrawRewardPool(uint256 amount) external override onlyOwner {
        require(amount <= rewardPool, "PuzzleManager: insufficient pool");
        rewardPool -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "PuzzleManager: transfer failed");
    }

    function startSolving(uint256 puzzleId) external {
        require(puzzles[puzzleId].active, "PuzzleManager: puzzle not active");
        require(
            !hasSolved[puzzleId][msg.sender],
            "PuzzleManager: already solved"
        );

        if (solveStartTime[msg.sender] == 0) {
            solveStartTime[msg.sender] = block.timestamp;
        }
    }

    // STAKING FUNCTIONS
    function stakeToPuzzle(uint256 puzzleId) external payable whenNotPaused {
        Puzzle memory puzzle = puzzles[puzzleId];
        require(puzzle.active, "PuzzleManager: puzzle not active");
        require(
            block.timestamp >= puzzle.startTime,
            "PuzzleManager: puzzle not started"
        );
        require(
            block.timestamp < puzzle.endTime,
            "PuzzleManager: puzzle ended"
        );
        require(
            !hasSolved[puzzleId][msg.sender],
            "PuzzleManager: already solved"
        );
        require(
            puzzleStakeAmount[puzzleId] > 0,
            "PuzzleManager: staking not enabled for this puzzle"
        );
        require(
            msg.value >= puzzleStakeAmount[puzzleId],
            "PuzzleManager: insufficient stake"
        );
        require(
            playerStakes[puzzleId][msg.sender] == 0,
            "PuzzleManager: already staked"
        );

        playerStakes[puzzleId][msg.sender] = msg.value;
        puzzleStakePool[puzzleId] += msg.value;
    }

    function unstake(uint256 puzzleId) external nonReentrant {
        Puzzle memory puzzle = puzzles[puzzleId];
        require(
            !puzzle.active || block.timestamp >= puzzle.endTime,
            "PuzzleManager: puzzle still active"
        );
        require(
            playerStakes[puzzleId][msg.sender] > 0,
            "PuzzleManager: no stake"
        );
        require(
            !hasSolved[puzzleId][msg.sender],
            "PuzzleManager: puzzle solved, claim reward instead"
        );

        uint256 stakeAmount = playerStakes[puzzleId][msg.sender];
        playerStakes[puzzleId][msg.sender] = 0;
        puzzleStakePool[puzzleId] -= stakeAmount;

        (bool success, ) = msg.sender.call{value: stakeAmount}("");
        require(success, "PuzzleManager: unstake transfer failed");
    }

    function enableStakingForPuzzle(
        uint256 puzzleId,
        uint256 stakeAmount
    ) external onlyOwner {
        require(
            puzzles[puzzleId].id > 0,
            "PuzzleManager: puzzle does not exist"
        );
        puzzleStakeAmount[puzzleId] = stakeAmount;
    }

    // HINT SYSTEM FUNCTIONS
    function addHintToPuzzle(
        uint256 puzzleId,
        string memory hint
    ) external onlyOwner {
        require(
            puzzles[puzzleId].id > 0,
            "PuzzleManager: puzzle does not exist"
        );
        puzzleHints[puzzleId].push(hint);
    }

    function buyHint(
        uint256 puzzleId
    ) external whenNotPaused returns (string memory) {
        Puzzle memory puzzle = puzzles[puzzleId];
        require(puzzle.active, "PuzzleManager: puzzle not active");
        require(
            !hasSolved[puzzleId][msg.sender],
            "PuzzleManager: already solved"
        );

        uint256 hintsUsedCount = hintsUsed[msg.sender][puzzleId];
        require(
            hintsUsedCount < puzzleHints[puzzleId].length,
            "PuzzleManager: no more hints"
        );

        // Check player has enough points
        uint256 hintCost = hintCostPoints * (hintsUsedCount + 1); // Escalating cost
        require(
            playerScore[msg.sender] >= hintCost,
            "PuzzleManager: insufficient points"
        );

        // Deduct points
        playerScore[msg.sender] -= hintCost;
        hintsUsed[msg.sender][puzzleId]++;

        return puzzleHints[puzzleId][hintsUsedCount];
    }

    function getHintCount(uint256 puzzleId) external view returns (uint256) {
        return puzzleHints[puzzleId].length;
    }

    function getPlayerHintsUsed(
        address player,
        uint256 puzzleId
    ) external view returns (uint256) {
        return hintsUsed[player][puzzleId];
    }

    function getNextHintCost(
        address player,
        uint256 puzzleId
    ) external view returns (uint256) {
        uint256 hintsUsedCount = hintsUsed[player][puzzleId];
        return hintCostPoints * (hintsUsedCount + 1);
    }

    // Read Functions
    function getPuzzle(
        uint256 puzzleId
    ) external view override returns (Puzzle memory) {
        return puzzles[puzzleId];
    }

    function getActivePuzzles()
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (
                puzzles[i].active &&
                block.timestamp >= puzzles[i].startTime &&
                block.timestamp < puzzles[i].endTime
            ) {
                count++;
            }
        }

        uint256[] memory activePuzzles = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (
                puzzles[i].active &&
                block.timestamp >= puzzles[i].startTime &&
                block.timestamp < puzzles[i].endTime
            ) {
                activePuzzles[index] = i;
                index++;
            }
        }

        return activePuzzles;
    }

    function getPuzzlesByDifficulty(
        uint256 difficulty
    ) external view override returns (uint256[] memory) {
        require(
            difficulty >= 1 && difficulty <= 4,
            "PuzzleManager: invalid difficulty"
        );

        uint256 count = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (puzzles[i].active && puzzles[i].difficulty == difficulty) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (puzzles[i].active && puzzles[i].difficulty == difficulty) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    function getPuzzlesByCategory(
        string memory category
    ) external view override returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (
                puzzles[i].active &&
                keccak256(abi.encodePacked(puzzles[i].category)) ==
                keccak256(abi.encodePacked(category))
            ) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (
                puzzles[i].active &&
                keccak256(abi.encodePacked(puzzles[i].category)) ==
                keccak256(abi.encodePacked(category))
            ) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    function hasPlayerSolved(
        address player,
        uint256 puzzleId
    ) external view override returns (bool) {
        return hasSolved[puzzleId][player];
    }

    function getPlayerStats(
        address player
    )
        external
        view
        override
        returns (uint256 score, uint256 streak, uint256 totalSolved)
    {
        return (
            playerScore[player],
            solveStreak[player],
            playerSolvedPuzzles[player].length
        );
    }

    function getPlayerSolvedPuzzles(
        address player
    ) external view override returns (uint256[] memory) {
        return playerSolvedPuzzles[player];
    }

    function getCurrentStreak(
        address player
    ) external view override returns (uint256) {
        return solveStreak[player];
    }

    function getRewardAmount(
        uint256 puzzleId
    ) external view override returns (uint256) {
        return puzzles[puzzleId].reward;
    }

    function getTotalSolvers(
        uint256 puzzleId
    ) external view override returns (uint256) {
        return puzzles[puzzleId].solveCount;
    }

    function isPuzzleActive(
        uint256 puzzleId
    ) external view override returns (bool) {
        Puzzle memory puzzle = puzzles[puzzleId];
        return
            puzzle.active &&
            block.timestamp >= puzzle.startTime &&
            block.timestamp < puzzle.endTime;
    }

    function getTimeRemaining(
        uint256 puzzleId
    ) external view override returns (uint256) {
        Puzzle memory puzzle = puzzles[puzzleId];
        if (block.timestamp >= puzzle.endTime) {
            return 0;
        }
        return puzzle.endTime - block.timestamp;
    }

    function getRewardPoolBalance() external view override returns (uint256) {
        return rewardPool;
    }

    function getDailyPuzzle() external view override returns (Puzzle memory) {
        uint256 daysSinceStart = (block.timestamp - dailyPuzzleStartDate) /
            DAY_IN_SECONDS;
        uint256 dailyPuzzleId = (daysSinceStart % currentPuzzleId) + 1;

        if (puzzles[dailyPuzzleId].active) {
            return puzzles[dailyPuzzleId];
        }

        // Find next active puzzle
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (
                puzzles[i].active &&
                block.timestamp >= puzzles[i].startTime &&
                block.timestamp < puzzles[i].endTime
            ) {
                return puzzles[i];
            }
        }

        return Puzzle(0, "", bytes32(0), 0, 0, 0, 0, 0, false, "");
    }

    // Username functions
    function getUsername(address player) external view returns (string memory) {
        return playerUsername[player];
    }

    function getAddressByUsername(
        string memory username
    ) external view returns (address) {
        return usernameToAddress[username];
    }

    function isUsernameAvailable(
        string memory username
    ) external view returns (bool) {
        return usernameToAddress[username] == address(0);
    }

    // Internal Functions
    function _updateStreak(address player) internal {
        uint256 lastSolve = lastSolveTime[player];
        uint256 currentDay = block.timestamp / DAY_IN_SECONDS;
        uint256 lastSolveDay = lastSolve / DAY_IN_SECONDS;

        if (lastSolve == 0) {
            // First solve
            solveStreak[player] = 1;
        } else if (currentDay == lastSolveDay) {
            // Same day, don't update streak
            return;
        } else if (currentDay == lastSolveDay + 1) {
            // Consecutive day
            solveStreak[player]++;
        } else {
            // Streak broken
            solveStreak[player] = 1;
        }

        lastSolveTime[player] = block.timestamp;

        if (solveStreak[player] > longestStreak[player]) {
            longestStreak[player] = solveStreak[player];
        }
    }

    function _calculateRarity(
        uint256 difficulty,
        uint256 solveCount
    ) internal pure returns (uint256) {
        // Rarity calculation based on difficulty and solve rank
        // 1=Common, 2=Rare, 3=Epic, 4=Legendary

        if (solveCount <= 3) {
            // Top 3 solvers get legendary for expert, epic for hard
            if (difficulty == 4) return 4; // Legendary
            if (difficulty == 3) return 3; // Epic
        }

        if (solveCount <= 10) {
            // Top 10 solvers
            if (difficulty >= 3) return 3; // Epic
            if (difficulty == 2) return 2; // Rare
        }

        if (solveCount <= 50) {
            // Top 50 solvers
            if (difficulty >= 3) return 2; // Rare
            return 1; // Common
        }

        // Default rarity based on difficulty
        if (difficulty == 4) return 2; // Rare
        if (difficulty == 3) return 1; // Common
        return 1; // Common
    }

    // Receive function
    receive() external payable {
        rewardPool += msg.value;
    }
}
