// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/gamification/AchievementManager.sol";

contract AchievementManagerTest is Test {
    AchievementManager public achievementManager;

    address public owner;
    address public authorizedCaller;
    address public player1;
    address public player2;

    function setUp() public {
        owner = address(this);
        authorizedCaller = makeAddr("authorizedCaller");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");

        achievementManager = new AchievementManager();
        achievementManager.setAuthorizedCaller(authorizedCaller, true);
    }

    function testInitialAchievementsCreated() public {
        // Should have default achievements
        IAchievementManager.Achievement memory achievement = achievementManager
            .getAchievement(1);
        assertEq(achievement.name, "First Blood");
        assertTrue(achievement.active);
    }

    function testCreateAchievement() public {
        uint256 achievementId = achievementManager.createAchievement(
            "Test Achievement",
            "Test Description",
            500,
            "badge_test",
            false,
            0
        );

        assertGt(achievementId, 0);

        IAchievementManager.Achievement memory achievement = achievementManager
            .getAchievement(achievementId);
        assertEq(achievement.name, "Test Achievement");
        assertEq(achievement.rewardPoints, 500);
        assertFalse(achievement.repeatable);
    }

    function testUnlockAchievement() public {
        vm.prank(authorizedCaller);
        achievementManager.unlockAchievement(player1, 1);

        assertTrue(achievementManager.hasAchievement(player1, 1));
        assertEq(achievementManager.getPlayerBadgeCount(player1), 1);

        // Check badge NFT was minted
        assertEq(achievementManager.balanceOf(player1), 1);
    }

    function testCannotUnlockNonRepeatableAchievementTwice() public {
        vm.startPrank(authorizedCaller);
        achievementManager.unlockAchievement(player1, 1);

        // Second unlock should not mint another badge for non-repeatable
        uint256 balanceBefore = achievementManager.balanceOf(player1);
        achievementManager.unlockAchievement(player1, 1);
        uint256 balanceAfter = achievementManager.balanceOf(player1);

        // Balance should stay the same
        assertEq(balanceBefore, balanceAfter);
        vm.stopPrank();
    }

    function testUnlockRepeatableAchievement() public {
        // Speed Demon is repeatable (ID 7)
        vm.startPrank(authorizedCaller);
        achievementManager.unlockAchievement(player1, 7);
        achievementManager.unlockAchievement(player1, 7);
        vm.stopPrank();

        // Should have 2 badges
        assertEq(achievementManager.balanceOf(player1), 2);
    }

    function testCheckAndUnlock() public {
        vm.prank(authorizedCaller);
        achievementManager.checkAndUnlock(player1, "first_solve");

        assertTrue(achievementManager.hasAchievement(player1, 1));
    }

    function testOnlyAuthorizedCanUnlock() public {
        vm.prank(player1);
        vm.expectRevert("AchievementManager: not authorized");
        achievementManager.unlockAchievement(player2, 1);
    }

    function testGetPlayerAchievements() public {
        vm.startPrank(authorizedCaller);
        achievementManager.unlockAchievement(player1, 1);
        achievementManager.unlockAchievement(player1, 2);
        achievementManager.unlockAchievement(player1, 3);
        vm.stopPrank();

        IAchievementManager.PlayerAchievement[]
            memory achievements = achievementManager.getPlayerAchievements(
                player1
            );

        assertEq(achievements.length, 3);
    }

    function testGetAchievementsByCategory() public {
        IAchievementManager.Achievement[]
            memory solvingAchievements = achievementManager
                .getAchievementsByCategory(0); // Solving category

        assertGt(solvingAchievements.length, 0);
    }

    function testGetAllAchievements() public {
        IAchievementManager.Achievement[]
            memory allAchievements = achievementManager.getAllAchievements();

        assertGt(allAchievements.length, 10); // Should have at least 10 default achievements
    }
}
