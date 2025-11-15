// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/gamification/ReferralManager.sol";
import "../src/gamification/AchievementManager.sol";

contract ReferralManagerTest is Test {
    ReferralManager public referralManager;
    AchievementManager public achievementManager;

    address public owner;
    address public puzzleManager;
    address public referrer;
    address public referred1;
    address public referred2;

    function setUp() public {
        owner = address(this);
        puzzleManager = makeAddr("puzzleManager");
        referrer = makeAddr("referrer");
        referred1 = makeAddr("referred1");
        referred2 = makeAddr("referred2");

        vm.deal(puzzleManager, 100 ether);

        referralManager = new ReferralManager();
        achievementManager = new AchievementManager();

        referralManager.setPuzzleManager(puzzleManager);
        referralManager.setAchievementManager(address(achievementManager));
    }

    function testRegisterReferral() public {
        referralManager.registerReferral(referred1, referrer);

        assertEq(referralManager.getReferrer(referred1), referrer);
        assertEq(referralManager.getReferralCount(referrer), 1);
        assertTrue(referralManager.isReferred(referred1));
    }

    function testCannotReferSelf() public {
        vm.expectRevert("ReferralManager: cannot refer self");
        referralManager.registerReferral(referrer, referrer);
    }

    function testCannotRegisterTwice() public {
        referralManager.registerReferral(referred1, referrer);

        vm.expectRevert("ReferralManager: already referred");
        referralManager.registerReferral(referred1, referrer);
    }

    function testPayReferralReward() public {
        referralManager.registerReferral(referred1, referrer);

        uint256 reward = 1 ether;
        uint256 expectedReferralReward = (reward * 5) / 100; // 5%

        uint256 balanceBefore = referrer.balance;

        // Fund the referral manager
        vm.deal(address(referralManager), 10 ether);

        vm.prank(puzzleManager);
        referralManager.payReferralReward(referrer, reward);

        uint256 balanceAfter = referrer.balance;
        assertEq(balanceAfter - balanceBefore, expectedReferralReward);
        assertEq(
            referralManager.getTotalEarnings(referrer),
            expectedReferralReward
        );
    }

    function testOnlyPuzzleManagerCanPayReward() public {
        referralManager.registerReferral(referred1, referrer);

        vm.prank(referred1);
        vm.expectRevert("ReferralManager: not puzzle manager");
        referralManager.payReferralReward(referrer, 1 ether);
    }

    function testGetReferralTree() public {
        referralManager.registerReferral(referred1, referrer);
        referralManager.registerReferral(referred2, referrer);

        address[] memory tree = referralManager.getReferralTree(referrer);
        assertEq(tree.length, 2);
        assertEq(tree[0], referred1);
        assertEq(tree[1], referred2);
    }

    function testGetReferralData() public {
        referralManager.registerReferral(referred1, referrer);

        // Check referred player's data
        IReferralManager.ReferralData memory referredData = referralManager
            .getReferralData(referred1);
        assertEq(referredData.referrer, referrer);
        assertGt(referredData.joinedAt, 0);

        // Check referrer's data
        IReferralManager.ReferralData memory referrerData = referralManager
            .getReferralData(referrer);
        assertEq(referrerData.referralCount, 1);
    }

    function testReferralMilestone() public {
        // Authorize achievement manager to unlock achievements
        achievementManager.setAuthorizedCaller(address(referralManager), true);

        // Register 10 referrals to trigger milestone
        for (uint256 i = 0; i < 10; i++) {
            address newReferred = makeAddr(
                string(abi.encodePacked("referred", i))
            );
            referralManager.registerReferral(newReferred, referrer);
        }

        assertEq(referralManager.getReferralCount(referrer), 10);
    }

    function testGetReferralReward() public view {
        uint256 amount = 1 ether;
        uint256 expectedReward = (amount * 5) / 100;
        uint256 actualReward = referralManager.getReferralReward(amount);

        assertEq(actualReward, expectedReward);
    }
}
