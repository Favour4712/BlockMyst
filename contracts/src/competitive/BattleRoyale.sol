// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IBattleRoyale.sol";
import "../interfaces/IPuzzleManager.sol";

contract BattleRoyale is Ownable, ReentrancyGuard, IBattleRoyale {
    // State variables
    mapping(uint256 => Battle) public battles;
    mapping(uint256 => mapping(address => BattlePlayer)) public battlePlayers;
    mapping(uint256 => address[]) public battlePlayerList;
    mapping(uint256 => mapping(address => bool)) public hasJoined;
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public hasAnswered;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;
    
    uint256 public currentBattleId;
    uint256 public entryFee = 0.1 ether;
    
    IPuzzleManager public puzzleManager;

    constructor() Ownable(msg.sender) {}

    modifier onlyActiveBattle(uint256 battleId) {
        require(battles[battleId].active, "BattleRoyale: battle not active");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "BattleRoyale: zero address");
        puzzleManager = IPuzzleManager(_puzzleManager);
    }

    function setEntryFee(uint256 _entryFee) external onlyOwner {
        entryFee = _entryFee;
    }

    // Write Functions
    function createBattle(uint256 prizePool, uint256[] memory puzzleIds, uint256 maxRounds) 
        external 
        override 
        onlyOwner 
        returns (uint256) 
    {
        require(puzzleIds.length >= maxRounds, "BattleRoyale: not enough puzzles");
        require(maxRounds >= 3, "BattleRoyale: need at least 3 rounds");

        currentBattleId++;
        uint256 battleId = currentBattleId;

        battles[battleId] = Battle({
            id: battleId,
            startTime: block.timestamp,
            prizePool: prizePool,
            puzzleIds: puzzleIds,
            currentRound: 0,
            maxRounds: maxRounds,
            active: true,
            completed: false
        });

        emit BattleCreated(battleId, prizePool, maxRounds);
        return battleId;
    }

    function joinBattle(uint256 battleId) external payable override onlyActiveBattle(battleId) {
        require(msg.value >= entryFee, "BattleRoyale: insufficient entry fee");
        require(!hasJoined[battleId][msg.sender], "BattleRoyale: already joined");
        require(battles[battleId].currentRound == 0, "BattleRoyale: battle already started");

        battlePlayers[battleId][msg.sender] = BattlePlayer({
            playerAddress: msg.sender,
            score: 0,
            roundsCompleted: 0,
            eliminated: false,
            eliminatedRound: 0
        });

        battlePlayerList[battleId].push(msg.sender);
        hasJoined[battleId][msg.sender] = true;

        // Add entry fee to prize pool
        battles[battleId].prizePool += msg.value;

        emit PlayerJoined(battleId, msg.sender);
    }

    function submitBattleAnswer(uint256 battleId, uint256 puzzleId, string memory answer) 
        external 
        override 
        onlyActiveBattle(battleId) 
    {
        require(hasJoined[battleId][msg.sender], "BattleRoyale: not in battle");
        require(!battlePlayers[battleId][msg.sender].eliminated, "BattleRoyale: player eliminated");
        require(!hasAnswered[battleId][msg.sender][puzzleId], "BattleRoyale: already answered");

        Battle memory battle = battles[battleId];
        require(puzzleId == battle.puzzleIds[battle.currentRound], "BattleRoyale: wrong puzzle");

        // Verify answer through PuzzleManager
        IPuzzleManager.Puzzle memory puzzle = puzzleManager.getPuzzle(puzzleId);
        bytes32 submittedHash = keccak256(abi.encodePacked(answer));
        
        if (submittedHash == puzzle.answerHash) {
            battlePlayers[battleId][msg.sender].score += puzzle.difficulty * 100;
            battlePlayers[battleId][msg.sender].roundsCompleted++;
        }

        hasAnswered[battleId][msg.sender][puzzleId] = true;
    }

    function endRound(uint256 battleId) external override onlyOwner onlyActiveBattle(battleId) {
        Battle storage battle = battles[battleId];
        require(battle.currentRound < battle.maxRounds, "BattleRoyale: all rounds completed");

        uint256 currentRound = battle.currentRound;
        address[] memory players = battlePlayerList[battleId];
        
        // Count active players
        uint256 activeCount = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (!battlePlayers[battleId][players[i]].eliminated) {
                activeCount++;
            }
        }

        require(activeCount > 1, "BattleRoyale: need at least 2 active players");

        // Calculate elimination threshold (bottom 50%)
        uint256 eliminationCount = activeCount / 2;
        
        // Sort players by score for this round
        address[] memory activePlayers = new address[](activeCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (!battlePlayers[battleId][players[i]].eliminated) {
                activePlayers[idx] = players[i];
                idx++;
            }
        }

        // Bubble sort by score
        for (uint256 i = 0; i < activePlayers.length; i++) {
            for (uint256 j = i + 1; j < activePlayers.length; j++) {
                if (battlePlayers[battleId][activePlayers[j]].score > 
                    battlePlayers[battleId][activePlayers[i]].score) {
                    address temp = activePlayers[i];
                    activePlayers[i] = activePlayers[j];
                    activePlayers[j] = temp;
                }
            }
        }

        // Eliminate bottom players
        uint256 eliminated = 0;
        for (uint256 i = activePlayers.length - 1; i >= activePlayers.length - eliminationCount && i < activePlayers.length; i--) {
            battlePlayers[battleId][activePlayers[i]].eliminated = true;
            battlePlayers[battleId][activePlayers[i]].eliminatedRound = currentRound + 1;
            emit PlayerEliminated(battleId, activePlayers[i], currentRound + 1);
            eliminated++;
        }

        battle.currentRound++;
        emit RoundCompleted(battleId, currentRound + 1, eliminated);
    }

    function completeBattle(uint256 battleId) external override onlyOwner onlyActiveBattle(battleId) {
        Battle storage battle = battles[battleId];
        require(battle.currentRound >= battle.maxRounds || _getActivePlayerCount(battleId) <= 10, 
                "BattleRoyale: battle not ready to complete");

        battle.active = false;
        battle.completed = true;

        // Get final winners (top 10)
        address[] memory winners = _getFinalWinners(battleId, 10);
        
        emit BattleCompleted(battleId, winners);
    }

    function claimBattlePrize(uint256 battleId) external override nonReentrant {
        Battle memory battle = battles[battleId];
        require(battle.completed, "BattleRoyale: battle not completed");
        require(hasJoined[battleId][msg.sender], "BattleRoyale: not in battle");
        require(!hasClaimed[battleId][msg.sender], "BattleRoyale: already claimed");
        require(!battlePlayers[battleId][msg.sender].eliminated, "BattleRoyale: player eliminated");

        address[] memory winners = _getFinalWinners(battleId, 10);
        uint256 rank = 11;
        
        for (uint256 i = 0; i < winners.length && i < 10; i++) {
            if (winners[i] == msg.sender) {
                rank = i + 1;
                break;
            }
        }

        require(rank <= 10, "BattleRoyale: not in top 10");

        uint256 prize = _calculatePrize(battle.prizePool, rank);
        hasClaimed[battleId][msg.sender] = true;

        (bool success, ) = msg.sender.call{value: prize}("");
        require(success, "BattleRoyale: transfer failed");

        emit PrizeDistributed(battleId, msg.sender, prize);
    }

    // Read Functions
    function getBattle(uint256 battleId) external view override returns (Battle memory) {
        return battles[battleId];
    }

    function getBattlePlayers(uint256 battleId) external view override returns (address[] memory) {
        return battlePlayerList[battleId];
    }

    function getPlayerBattleStats(uint256 battleId, address player) 
        external 
        view 
        override 
        returns (BattlePlayer memory) 
    {
        return battlePlayers[battleId][player];
    }

    function isPlayerInBattle(uint256 battleId, address player) 
        external 
        view 
        override 
        returns (bool) 
    {
        return hasJoined[battleId][player];
    }

    function getActiveBattle() external view override returns (Battle memory) {
        if (currentBattleId > 0 && battles[currentBattleId].active) {
            return battles[currentBattleId];
        }
        return Battle(0, 0, 0, new uint256[](0), 0, 0, false, false);
    }

    function getActivePlayersInBattle(uint256 battleId) external view returns (address[] memory) {
        address[] memory allPlayers = battlePlayerList[battleId];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allPlayers.length; i++) {
            if (!battlePlayers[battleId][allPlayers[i]].eliminated) {
                activeCount++;
            }
        }

        address[] memory activePlayers = new address[](activeCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < allPlayers.length; i++) {
            if (!battlePlayers[battleId][allPlayers[i]].eliminated) {
                activePlayers[idx] = allPlayers[i];
                idx++;
            }
        }

        return activePlayers;
    }

    // Internal Functions
    function _getActivePlayerCount(uint256 battleId) internal view returns (uint256) {
        address[] memory players = battlePlayerList[battleId];
        uint256 count = 0;
        
        for (uint256 i = 0; i < players.length; i++) {
            if (!battlePlayers[battleId][players[i]].eliminated) {
                count++;
            }
        }
        
        return count;
    }

    function _getFinalWinners(uint256 battleId, uint256 limit) internal view returns (address[] memory) {
        address[] memory allPlayers = battlePlayerList[battleId];
        uint256 activeCount = _getActivePlayerCount(battleId);
        
        address[] memory activePlayers = new address[](activeCount);
        uint256 idx = 0;
        
        for (uint256 i = 0; i < allPlayers.length; i++) {
            if (!battlePlayers[battleId][allPlayers[i]].eliminated) {
                activePlayers[idx] = allPlayers[i];
                idx++;
            }
        }

        // Sort by score
        for (uint256 i = 0; i < activePlayers.length; i++) {
            for (uint256 j = i + 1; j < activePlayers.length; j++) {
                if (battlePlayers[battleId][activePlayers[j]].score > 
                    battlePlayers[battleId][activePlayers[i]].score) {
                    address temp = activePlayers[i];
                    activePlayers[i] = activePlayers[j];
                    activePlayers[j] = temp;
                }
            }
        }

        uint256 resultSize = activePlayers.length < limit ? activePlayers.length : limit;
        address[] memory result = new address[](resultSize);
        
        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = activePlayers[i];
        }

        return result;
    }

    function _calculatePrize(uint256 totalPrize, uint256 rank) internal pure returns (uint256) {
        // Top 10 prize distribution
        if (rank == 1) return (totalPrize * 25) / 100;
        if (rank == 2) return (totalPrize * 18) / 100;
        if (rank == 3) return (totalPrize * 15) / 100;
        if (rank == 4) return (totalPrize * 12) / 100;
        if (rank == 5) return (totalPrize * 10) / 100;
        if (rank == 6) return (totalPrize * 8) / 100;
        if (rank == 7) return (totalPrize * 6) / 100;
        if (rank == 8) return (totalPrize * 3) / 100;
        if (rank == 9) return (totalPrize * 2) / 100;
        if (rank == 10) return (totalPrize * 1) / 100;
        
        return 0;
    }

    // Receive function
    receive() external payable {}
}

