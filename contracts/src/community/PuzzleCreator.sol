// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IPuzzleCreator.sol";
import "../interfaces/IProgressionManager.sol";

contract PuzzleCreator is Ownable, ReentrancyGuard, IPuzzleCreator {
    // State variables
    mapping(uint256 => CommunityPuzzle) public communityPuzzles;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256[]) public creatorPuzzles;
    mapping(address => uint256) public creatorTotalEarnings;
    
    uint256 public currentPuzzleId;
    uint256 public constant APPROVAL_THRESHOLD = 10; // Need 10 upvotes
    uint256 public creatorRewardPercentage = 15; // 15% of puzzle rewards go to creator
    
    IProgressionManager public progressionManager;
    address public puzzleManager;

    constructor() Ownable(msg.sender) {}

    modifier onlyPuzzleManager() {
        require(msg.sender == puzzleManager, "PuzzleCreator: not puzzle manager");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "PuzzleCreator: zero address");
        puzzleManager = _puzzleManager;
    }

    function setProgressionManager(address _progressionManager) external onlyOwner {
        require(_progressionManager != address(0), "PuzzleCreator: zero address");
        progressionManager = IProgressionManager(_progressionManager);
    }

    function setCreatorRewardPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 25, "PuzzleCreator: percentage too high");
        creatorRewardPercentage = percentage;
    }

    // Write Functions
    function submitPuzzle(
        string memory ipfsHash,
        bytes32 answerHash,
        uint256 difficulty,
        string memory category
    ) external override returns (uint256) {
        require(bytes(ipfsHash).length > 0, "PuzzleCreator: empty IPFS hash");
        require(answerHash != bytes32(0), "PuzzleCreator: empty answer hash");
        require(difficulty >= 1 && difficulty <= 4, "PuzzleCreator: invalid difficulty");
        
        // Check if player has unlocked puzzle creation skill
        if (address(progressionManager) != address(0)) {
            require(
                progressionManager.hasSkill(msg.sender, 7), // Skill ID 7 = Puzzle Creator
                "PuzzleCreator: puzzle creation skill not unlocked"
            );
        }

        currentPuzzleId++;
        uint256 puzzleId = currentPuzzleId;

        communityPuzzles[puzzleId] = CommunityPuzzle({
            id: puzzleId,
            creator: msg.sender,
            ipfsHash: ipfsHash,
            answerHash: answerHash,
            difficulty: difficulty,
            category: category,
            createdAt: block.timestamp,
            voteCount: 0,
            playCount: 0,
            approvalStatus: 0, // Pending
            creatorEarnings: 0,
            active: false
        });

        creatorPuzzles[msg.sender].push(puzzleId);

        emit PuzzleSubmitted(puzzleId, msg.sender);
        return puzzleId;
    }

    function votePuzzle(uint256 puzzleId, bool upvote) external override {
        CommunityPuzzle storage puzzle = communityPuzzles[puzzleId];
        require(puzzle.id > 0, "PuzzleCreator: puzzle does not exist");
        require(puzzle.approvalStatus == 0, "PuzzleCreator: puzzle already processed");
        require(!hasVoted[puzzleId][msg.sender], "PuzzleCreator: already voted");
        require(msg.sender != puzzle.creator, "PuzzleCreator: cannot vote own puzzle");

        hasVoted[puzzleId][msg.sender] = true;

        if (upvote) {
            puzzle.voteCount++;
            emit PuzzleVoted(puzzleId, msg.sender, true);
            
            // Auto-approve if threshold reached
            if (puzzle.voteCount >= APPROVAL_THRESHOLD) {
                _approvePuzzle(puzzleId);
            }
        } else {
            emit PuzzleVoted(puzzleId, msg.sender, false);
        }
    }

    function approvePuzzle(uint256 puzzleId) external override onlyOwner {
        _approvePuzzle(puzzleId);
    }

    function rejectPuzzle(uint256 puzzleId) external override onlyOwner {
        CommunityPuzzle storage puzzle = communityPuzzles[puzzleId];
        require(puzzle.id > 0, "PuzzleCreator: puzzle does not exist");
        require(puzzle.approvalStatus == 0, "PuzzleCreator: puzzle already processed");

        puzzle.approvalStatus = 2; // Rejected
        
        emit PuzzleRejected(puzzleId);
    }

    function payCreator(uint256 puzzleId, uint256 amount) 
        external 
        override 
        onlyPuzzleManager 
        nonReentrant 
    {
        CommunityPuzzle storage puzzle = communityPuzzles[puzzleId];
        require(puzzle.id > 0, "PuzzleCreator: puzzle does not exist");
        require(puzzle.approvalStatus == 1, "PuzzleCreator: puzzle not approved");

        puzzle.playCount++;

        uint256 creatorReward = (amount * creatorRewardPercentage) / 100;
        puzzle.creatorEarnings += creatorReward;
        creatorTotalEarnings[puzzle.creator] += creatorReward;

        (bool success, ) = puzzle.creator.call{value: creatorReward}("");
        require(success, "PuzzleCreator: transfer failed");

        emit CreatorRewarded(puzzleId, puzzle.creator, creatorReward);
    }

    // Read Functions
    function getCommunityPuzzle(uint256 puzzleId) external view override returns (CommunityPuzzle memory) {
        return communityPuzzles[puzzleId];
    }

    function getPendingPuzzles() external view override returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (communityPuzzles[i].approvalStatus == 0) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (communityPuzzles[i].approvalStatus == 0) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    function getApprovedPuzzles() external view override returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (communityPuzzles[i].approvalStatus == 1 && communityPuzzles[i].active) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentPuzzleId; i++) {
            if (communityPuzzles[i].approvalStatus == 1 && communityPuzzles[i].active) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    function getCreatorPuzzles(address creator) external view override returns (uint256[] memory) {
        return creatorPuzzles[creator];
    }

    function getCreatorEarnings(address creator) external view override returns (uint256) {
        return creatorTotalEarnings[creator];
    }

    function getTopCreators(uint256 limit) external view returns (address[] memory) {
        // Simplified - in production, maintain sorted array
        address[] memory creators = new address[](limit);
        uint256[] memory earnings = new uint256[](limit);
        
        // This is a placeholder - would need better implementation
        return creators;
    }

    // Internal Functions
    function _approvePuzzle(uint256 puzzleId) internal {
        CommunityPuzzle storage puzzle = communityPuzzles[puzzleId];
        require(puzzle.id > 0, "PuzzleCreator: puzzle does not exist");
        require(puzzle.approvalStatus == 0, "PuzzleCreator: puzzle already processed");

        puzzle.approvalStatus = 1; // Approved
        puzzle.active = true;

        emit PuzzleApproved(puzzleId);
    }

    // Receive function
    receive() external payable {}
}

