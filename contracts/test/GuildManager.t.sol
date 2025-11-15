// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/social/GuildManager.sol";

contract GuildManagerTest is Test {
    GuildManager public guildManager;

    address public owner;
    address public puzzleManager;
    address public leader;
    address public member1;
    address public member2;
    address public member3;

    function setUp() public {
        owner = address(this);
        puzzleManager = makeAddr("puzzleManager");
        leader = makeAddr("leader");
        member1 = makeAddr("member1");
        member2 = makeAddr("member2");
        member3 = makeAddr("member3");

        guildManager = new GuildManager();
        guildManager.setPuzzleManager(puzzleManager);
    }

    function testCreateGuild() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        assertEq(guildId, 1);

        IGuildManager.Guild memory guild = guildManager.getGuild(guildId);
        assertEq(guild.name, "Test Guild");
        assertEq(guild.leader, leader);
        assertEq(guild.memberCount, 1);
        assertTrue(guild.active);
    }

    function testCannotCreateGuildIfAlreadyInOne() public {
        vm.startPrank(leader);
        guildManager.createGuild("Guild 1", "First guild");

        vm.expectRevert("GuildManager: already in guild");
        guildManager.createGuild("Guild 2", "Second guild");
        vm.stopPrank();
    }

    function testJoinGuild() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        assertTrue(guildManager.isInGuild(member1));
        assertEq(guildManager.getPlayerGuild(member1), guildId);

        IGuildManager.Guild memory guild = guildManager.getGuild(guildId);
        assertEq(guild.memberCount, 2);
    }

    function testCannotJoinIfAlreadyInGuild() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.startPrank(member1);
        guildManager.joinGuild(guildId);

        vm.expectRevert("GuildManager: already in guild");
        guildManager.joinGuild(guildId);
        vm.stopPrank();
    }

    function testLeaveGuild() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.startPrank(member1);
        guildManager.joinGuild(guildId);
        guildManager.leaveGuild();
        vm.stopPrank();

        assertFalse(guildManager.isInGuild(member1));
        assertEq(guildManager.getPlayerGuild(member1), 0);
    }

    function testLeaderCannotLeave() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(leader);
        vm.expectRevert(
            "GuildManager: leader cannot leave (transfer or disband)"
        );
        guildManager.leaveGuild();
    }

    function testDisbandGuild() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(leader);
        guildManager.disbandGuild(guildId);

        IGuildManager.Guild memory guild = guildManager.getGuild(guildId);
        assertFalse(guild.active);
        assertFalse(guildManager.isInGuild(member1));
    }

    function testContributePoints() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(puzzleManager);
        guildManager.contributePoints(leader, 1000);

        IGuildManager.Guild memory guild = guildManager.getGuild(guildId);
        assertEq(guild.totalPoints, 1000);

        IGuildManager.GuildMember memory memberInfo = guildManager
            .getGuildMemberInfo(guildId, leader);
        assertEq(memberInfo.contributedPoints, 1000);
    }

    function testPromoteToOfficer() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(leader);
        guildManager.promoteToOfficer(guildId, member1);

        IGuildManager.GuildMember memory memberInfo = guildManager
            .getGuildMemberInfo(guildId, member1);
        assertTrue(memberInfo.isOfficer);
    }

    function testKickMember() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(leader);
        guildManager.kickMember(guildId, member1);

        assertFalse(guildManager.isInGuild(member1));
    }

    function testCannotKickLeader() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(member1);
        vm.expectRevert();
        guildManager.kickMember(guildId, leader);
    }

    function testGetGuildLeaderboard() public {
        // Create multiple guilds
        vm.prank(leader);
        uint256 guild1 = guildManager.createGuild("Guild 1", "First");

        vm.prank(member1);
        uint256 guild2 = guildManager.createGuild("Guild 2", "Second");

        vm.prank(member2);
        uint256 guild3 = guildManager.createGuild("Guild 3", "Third");

        // Add points
        vm.startPrank(puzzleManager);
        guildManager.contributePoints(leader, 1000);
        guildManager.contributePoints(member1, 2000);
        guildManager.contributePoints(member2, 500);
        vm.stopPrank();

        IGuildManager.Guild[] memory leaderboard = guildManager
            .getGuildLeaderboard(10);

        assertEq(leaderboard.length, 3);
        // Should be sorted by points
        assertGe(leaderboard[0].totalPoints, leaderboard[1].totalPoints);
    }

    function testTransferLeadership() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(leader);
        guildManager.transferLeadership(guildId, member1);

        IGuildManager.Guild memory guild = guildManager.getGuild(guildId);
        assertEq(guild.leader, member1);
    }

    function testGetGuildMembers() public {
        vm.prank(leader);
        uint256 guildId = guildManager.createGuild(
            "Test Guild",
            "A test guild"
        );

        vm.prank(member1);
        guildManager.joinGuild(guildId);

        vm.prank(member2);
        guildManager.joinGuild(guildId);

        address[] memory members = guildManager.getGuildMembers(guildId);
        assertEq(members.length, 3);
    }
}
