// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/community/PuzzleCreator.sol";
import "../src/interfaces/IPuzzleCreator.sol";

contract PuzzleCreatorTest is Test {
    PuzzleCreator public puzzleCreator;
    
    address public owner;
    address public creator1;
    address public voter1;
    address public voter2;
    
    event PuzzleSubmitted(uint256 indexed puzzleId, address indexed creator);
    event PuzzleVoted(uint256 indexed puzzleId, address indexed voter, bool upvote);
    event PuzzleApproved(uint256 indexed puzzleId);
    event PuzzleRejected(uint256 indexed puzzleId);
    
    function setUp() public {
        owner = address(this);
        creator1 = makeAddr("creator1");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        
        puzzleCreator = new PuzzleCreator();
        vm.deal(address(puzzleCreator), 10 ether);
    }
    
    function testSubmitPuzzle() public {
        vm.prank(creator1);
        vm.expectEmit(true, true, false, false);
        emit PuzzleSubmitted(1, creator1);
        
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        assertEq(puzzleId, 1);
        
        IPuzzleCreator.CommunityPuzzle memory puzzle = puzzleCreator.getCommunityPuzzle(puzzleId);
        assertEq(puzzle.creator, creator1);
        assertEq(puzzle.approvalStatus, 0); // Pending
    }
    
    function testVotePuzzle() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        vm.prank(voter1);
        vm.expectEmit(true, true, false, true);
        emit PuzzleVoted(puzzleId, voter1, true);
        
        puzzleCreator.votePuzzle(puzzleId, true);
        
        IPuzzleCreator.CommunityPuzzle memory puzzle = puzzleCreator.getCommunityPuzzle(puzzleId);
        assertEq(puzzle.voteCount, 1);
    }
    
    function testCannotVoteTwice() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        vm.startPrank(voter1);
        puzzleCreator.votePuzzle(puzzleId, true);
        
        vm.expectRevert("PuzzleCreator: already voted");
        puzzleCreator.votePuzzle(puzzleId, true);
        vm.stopPrank();
    }
    
    function testCreatorCannotVoteOwnPuzzle() public {
        vm.startPrank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        vm.expectRevert("PuzzleCreator: cannot vote own puzzle");
        puzzleCreator.votePuzzle(puzzleId, true);
        vm.stopPrank();
    }
    
    function testApprovePuzzle() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        vm.expectEmit(true, false, false, false);
        emit PuzzleApproved(puzzleId);
        
        puzzleCreator.approvePuzzle(puzzleId);
        
        IPuzzleCreator.CommunityPuzzle memory puzzle = puzzleCreator.getCommunityPuzzle(puzzleId);
        assertEq(puzzle.approvalStatus, 1); // Approved
        assertTrue(puzzle.active);
    }
    
    function testRejectPuzzle() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        vm.expectEmit(true, false, false, false);
        emit PuzzleRejected(puzzleId);
        
        puzzleCreator.rejectPuzzle(puzzleId);
        
        IPuzzleCreator.CommunityPuzzle memory puzzle = puzzleCreator.getCommunityPuzzle(puzzleId);
        assertEq(puzzle.approvalStatus, 2); // Rejected
    }
    
    function testGetPendingPuzzles() public {
        vm.prank(creator1);
        puzzleCreator.submitPuzzle("QmTest1", keccak256(abi.encodePacked("answer1")), 2, "DeFi");
        
        vm.prank(creator1);
        puzzleCreator.submitPuzzle("QmTest2", keccak256(abi.encodePacked("answer2")), 3, "NFTs");
        
        uint256[] memory pending = puzzleCreator.getPendingPuzzles();
        assertEq(pending.length, 2);
    }
    
    function testGetApprovedPuzzles() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        puzzleCreator.approvePuzzle(puzzleId);
        
        uint256[] memory approved = puzzleCreator.getApprovedPuzzles();
        assertEq(approved.length, 1);
        assertEq(approved[0], puzzleId);
    }
    
    function testGetCreatorPuzzles() public {
        vm.startPrank(creator1);
        puzzleCreator.submitPuzzle("QmTest1", keccak256(abi.encodePacked("answer1")), 2, "DeFi");
        puzzleCreator.submitPuzzle("QmTest2", keccak256(abi.encodePacked("answer2")), 3, "NFTs");
        vm.stopPrank();
        
        uint256[] memory creatorPuzzles = puzzleCreator.getCreatorPuzzles(creator1);
        assertEq(creatorPuzzles.length, 2);
    }
    
    function testAutoApprovalWithVotes() public {
        vm.prank(creator1);
        uint256 puzzleId = puzzleCreator.submitPuzzle(
            "QmTest",
            keccak256(abi.encodePacked("answer")),
            2,
            "DeFi"
        );
        
        // Need 10 votes for auto-approval
        for (uint256 i = 0; i < 10; i++) {
            address voter = makeAddr(string(abi.encodePacked("voter", i)));
            vm.prank(voter);
            puzzleCreator.votePuzzle(puzzleId, true);
        }
        
        IPuzzleCreator.CommunityPuzzle memory puzzle = puzzleCreator.getCommunityPuzzle(puzzleId);
        assertEq(puzzle.approvalStatus, 1); // Should be auto-approved
        assertTrue(puzzle.active);
    }
    
    receive() external payable {}
}
