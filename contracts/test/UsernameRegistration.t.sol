// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/PuzzleManager.sol";

contract UsernameRegistrationTest is Test {
    PuzzleManager public puzzleManager;
    
    address public player1;
    address public player2;
    address public player3;
    
    event UsernameRegistered(address indexed player, string username);
    
    function setUp() public {
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        
        puzzleManager = new PuzzleManager();
    }
    
    function testRegisterUsername() public {
        vm.prank(player1);
        
        vm.expectEmit(true, false, false, true);
        emit UsernameRegistered(player1, "alice");
        
        puzzleManager.registerUsername("alice");
        
        assertEq(puzzleManager.getUsername(player1), "alice");
        assertEq(puzzleManager.getAddressByUsername("alice"), player1);
        assertTrue(puzzleManager.hasRegistered(player1));
    }
    
    function testCannotRegisterTwice() public {
        vm.startPrank(player1);
        puzzleManager.registerUsername("alice");
        
        vm.expectRevert("PuzzleManager: already registered");
        puzzleManager.registerUsername("bob");
        vm.stopPrank();
    }
    
    function testCannotTakeSameUsername() public {
        vm.prank(player1);
        puzzleManager.registerUsername("alice");
        
        vm.prank(player2);
        vm.expectRevert("PuzzleManager: username taken");
        puzzleManager.registerUsername("alice");
    }
    
    function testUsernameTooShort() public {
        vm.prank(player1);
        vm.expectRevert("PuzzleManager: username too short");
        puzzleManager.registerUsername("ab");
    }
    
    function testUsernameTooLong() public {
        vm.prank(player1);
        vm.expectRevert("PuzzleManager: username too long");
        puzzleManager.registerUsername("thisusernameiswaytoolong");
    }
    
    function testInvalidCharacters() public {
        vm.prank(player1);
        vm.expectRevert("PuzzleManager: invalid characters");
        puzzleManager.registerUsername("alice!");
        
        vm.prank(player2);
        vm.expectRevert("PuzzleManager: invalid characters");
        puzzleManager.registerUsername("bob@test");
        
        vm.prank(player3);
        vm.expectRevert("PuzzleManager: invalid characters");
        puzzleManager.registerUsername("charlie$");
    }
    
    function testValidCharacters() public {
        vm.prank(player1);
        puzzleManager.registerUsername("alice_123");
        assertEq(puzzleManager.getUsername(player1), "alice_123");
        
        vm.prank(player2);
        puzzleManager.registerUsername("bob-456");
        assertEq(puzzleManager.getUsername(player2), "bob-456");
        
        vm.prank(player3);
        puzzleManager.registerUsername("Charlie789");
        assertEq(puzzleManager.getUsername(player3), "Charlie789");
    }
    
    function testIsUsernameAvailable() public {
        assertTrue(puzzleManager.isUsernameAvailable("alice"));
        
        vm.prank(player1);
        puzzleManager.registerUsername("alice");
        
        assertFalse(puzzleManager.isUsernameAvailable("alice"));
        assertTrue(puzzleManager.isUsernameAvailable("bob"));
    }
    
    function testGetAddressByNonExistentUsername() public view {
        address result = puzzleManager.getAddressByUsername("nonexistent");
        assertEq(result, address(0));
    }
    
    function testGetUsernameForUnregisteredPlayer() public view {
        string memory result = puzzleManager.getUsername(player1);
        assertEq(bytes(result).length, 0);
    }
    
    function testMultipleRegistrations() public {
        vm.prank(player1);
        puzzleManager.registerUsername("alice");
        
        vm.prank(player2);
        puzzleManager.registerUsername("bob");
        
        vm.prank(player3);
        puzzleManager.registerUsername("charlie");
        
        assertEq(puzzleManager.getUsername(player1), "alice");
        assertEq(puzzleManager.getUsername(player2), "bob");
        assertEq(puzzleManager.getUsername(player3), "charlie");
        
        assertEq(puzzleManager.getAddressByUsername("alice"), player1);
        assertEq(puzzleManager.getAddressByUsername("bob"), player2);
        assertEq(puzzleManager.getAddressByUsername("charlie"), player3);
    }
}

