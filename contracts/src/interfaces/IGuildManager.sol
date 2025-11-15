// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGuildManager {
    struct Guild {
        uint256 id;
        string name;
        string description;
        address leader;
        uint256 memberCount;
        uint256 totalPoints;
        uint256 createdAt;
        bool active;
        uint256 maxMembers;
    }

    struct GuildMember {
        address memberAddress;
        uint256 joinedAt;
        uint256 contributedPoints;
        bool isOfficer;
    }

    event GuildCreated(uint256 indexed guildId, string name, address indexed leader);
    event MemberJoined(uint256 indexed guildId, address indexed member);
    event MemberLeft(uint256 indexed guildId, address indexed member);
    event GuildDisbanded(uint256 indexed guildId);
    event PointsContributed(uint256 indexed guildId, address indexed member, uint256 points);
    event OfficerPromoted(uint256 indexed guildId, address indexed member);

    function createGuild(string memory name, string memory description) external returns (uint256);
    function joinGuild(uint256 guildId) external;
    function leaveGuild() external;
    function disbandGuild(uint256 guildId) external;
    function contributePoints(address member, uint256 points) external;
    function promoteToOfficer(uint256 guildId, address member) external;
    function kickMember(uint256 guildId, address member) external;
    
    function getGuild(uint256 guildId) external view returns (Guild memory);
    function getGuildMembers(uint256 guildId) external view returns (address[] memory);
    function getPlayerGuild(address player) external view returns (uint256);
    function isInGuild(address player) external view returns (bool);
    function getGuildLeaderboard(uint256 limit) external view returns (Guild[] memory);
    function getTotalGuilds() external view returns (uint256);
}

