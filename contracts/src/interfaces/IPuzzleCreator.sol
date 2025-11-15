// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPuzzleCreator {
    struct CommunityPuzzle {
        uint256 id;
        address creator;
        string ipfsHash;
        bytes32 answerHash;
        uint256 difficulty;
        string category;
        uint256 createdAt;
        uint256 voteCount;
        uint256 playCount;
        uint256 approvalStatus; // 0=Pending, 1=Approved, 2=Rejected
        uint256 creatorEarnings;
        bool active;
    }

    event PuzzleSubmitted(uint256 indexed puzzleId, address indexed creator);
    event PuzzleVoted(uint256 indexed puzzleId, address indexed voter, bool upvote);
    event PuzzleApproved(uint256 indexed puzzleId);
    event PuzzleRejected(uint256 indexed puzzleId);
    event CreatorRewarded(uint256 indexed puzzleId, address indexed creator, uint256 amount);

    function submitPuzzle(
        string memory ipfsHash,
        bytes32 answerHash,
        uint256 difficulty,
        string memory category
    ) external returns (uint256);

    function votePuzzle(uint256 puzzleId, bool upvote) external;
    function approvePuzzle(uint256 puzzleId) external;
    function rejectPuzzle(uint256 puzzleId) external;
    function payCreator(uint256 puzzleId, uint256 amount) external;
    
    function getCommunityPuzzle(uint256 puzzleId) external view returns (CommunityPuzzle memory);
    function getPendingPuzzles() external view returns (uint256[] memory);
    function getApprovedPuzzles() external view returns (uint256[] memory);
    function getCreatorPuzzles(address creator) external view returns (uint256[] memory);
    function getCreatorEarnings(address creator) external view returns (uint256);
}

