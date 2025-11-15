// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGuildManager.sol";

contract GuildManager is Ownable, IGuildManager {
    // State variables
    mapping(uint256 => Guild) public guilds;
    mapping(uint256 => mapping(address => GuildMember)) public guildMembers;
    mapping(uint256 => address[]) public guildMemberList;
    mapping(address => uint256) public playerGuild; // player => guildId (0 = no guild)
    
    uint256 public currentGuildId;
    uint256 public constant MAX_GUILD_MEMBERS = 50;
    uint256 public constant MIN_GUILD_NAME_LENGTH = 3;
    uint256 public constant MAX_GUILD_NAME_LENGTH = 32;
    
    address public puzzleManager;

    constructor() Ownable(msg.sender) {}

    modifier onlyPuzzleManager() {
        require(msg.sender == puzzleManager, "GuildManager: not puzzle manager");
        _;
    }

    modifier onlyGuildLeader(uint256 guildId) {
        require(guilds[guildId].leader == msg.sender, "GuildManager: not guild leader");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "GuildManager: zero address");
        puzzleManager = _puzzleManager;
    }

    // Write Functions
    function createGuild(string memory name, string memory description) 
        external 
        override 
        returns (uint256) 
    {
        require(bytes(name).length >= MIN_GUILD_NAME_LENGTH, "GuildManager: name too short");
        require(bytes(name).length <= MAX_GUILD_NAME_LENGTH, "GuildManager: name too long");
        require(playerGuild[msg.sender] == 0, "GuildManager: already in guild");

        currentGuildId++;
        uint256 guildId = currentGuildId;

        guilds[guildId] = Guild({
            id: guildId,
            name: name,
            description: description,
            leader: msg.sender,
            memberCount: 1,
            totalPoints: 0,
            createdAt: block.timestamp,
            active: true,
            maxMembers: MAX_GUILD_MEMBERS
        });

        // Add creator as first member
        guildMembers[guildId][msg.sender] = GuildMember({
            memberAddress: msg.sender,
            joinedAt: block.timestamp,
            contributedPoints: 0,
            isOfficer: true
        });

        guildMemberList[guildId].push(msg.sender);
        playerGuild[msg.sender] = guildId;

        emit GuildCreated(guildId, name, msg.sender);
        emit MemberJoined(guildId, msg.sender);

        return guildId;
    }

    function joinGuild(uint256 guildId) external override {
        Guild storage guild = guilds[guildId];
        require(guild.active, "GuildManager: guild not active");
        require(guild.memberCount < guild.maxMembers, "GuildManager: guild full");
        require(playerGuild[msg.sender] == 0, "GuildManager: already in guild");
        require(guildMembers[guildId][msg.sender].joinedAt == 0, "GuildManager: already member");

        guildMembers[guildId][msg.sender] = GuildMember({
            memberAddress: msg.sender,
            joinedAt: block.timestamp,
            contributedPoints: 0,
            isOfficer: false
        });

        guildMemberList[guildId].push(msg.sender);
        playerGuild[msg.sender] = guildId;
        guild.memberCount++;

        emit MemberJoined(guildId, msg.sender);
    }

    function leaveGuild() external override {
        uint256 guildId = playerGuild[msg.sender];
        require(guildId > 0, "GuildManager: not in guild");

        Guild storage guild = guilds[guildId];
        require(guild.leader != msg.sender, "GuildManager: leader cannot leave (transfer or disband)");

        _removeMember(guildId, msg.sender);
        
        emit MemberLeft(guildId, msg.sender);
    }

    function disbandGuild(uint256 guildId) external override onlyGuildLeader(guildId) {
        Guild storage guild = guilds[guildId];
        require(guild.active, "GuildManager: guild not active");

        guild.active = false;

        // Remove all members
        address[] memory members = guildMemberList[guildId];
        for (uint256 i = 0; i < members.length; i++) {
            playerGuild[members[i]] = 0;
        }

        emit GuildDisbanded(guildId);
    }

    function contributePoints(address member, uint256 points) external override onlyPuzzleManager {
        uint256 guildId = playerGuild[member];
        if (guildId > 0 && guilds[guildId].active) {
            guildMembers[guildId][member].contributedPoints += points;
            guilds[guildId].totalPoints += points;
            
            emit PointsContributed(guildId, member, points);
        }
    }

    function promoteToOfficer(uint256 guildId, address member) 
        external 
        override 
        onlyGuildLeader(guildId) 
    {
        require(guildMembers[guildId][member].joinedAt > 0, "GuildManager: not a member");
        guildMembers[guildId][member].isOfficer = true;
        
        emit OfficerPromoted(guildId, member);
    }

    function kickMember(uint256 guildId, address member) external override {
        require(
            guilds[guildId].leader == msg.sender || 
            guildMembers[guildId][msg.sender].isOfficer,
            "GuildManager: not authorized"
        );
        require(member != guilds[guildId].leader, "GuildManager: cannot kick leader");
        require(guildMembers[guildId][member].joinedAt > 0, "GuildManager: not a member");

        _removeMember(guildId, member);
        
        emit MemberLeft(guildId, member);
    }

    function transferLeadership(uint256 guildId, address newLeader) external onlyGuildLeader(guildId) {
        require(guildMembers[guildId][newLeader].joinedAt > 0, "GuildManager: not a member");
        guilds[guildId].leader = newLeader;
        guildMembers[guildId][newLeader].isOfficer = true;
    }

    // Read Functions
    function getGuild(uint256 guildId) external view override returns (Guild memory) {
        return guilds[guildId];
    }

    function getGuildMembers(uint256 guildId) external view override returns (address[] memory) {
        return guildMemberList[guildId];
    }

    function getPlayerGuild(address player) external view override returns (uint256) {
        return playerGuild[player];
    }

    function isInGuild(address player) external view override returns (bool) {
        return playerGuild[player] > 0;
    }

    function getGuildLeaderboard(uint256 limit) external view override returns (Guild[] memory) {
        uint256 totalGuilds = currentGuildId;
        uint256 activeCount = 0;

        // Count active guilds
        for (uint256 i = 1; i <= totalGuilds; i++) {
            if (guilds[i].active) {
                activeCount++;
            }
        }

        uint256 resultSize = activeCount < limit ? activeCount : limit;
        Guild[] memory activeGuilds = new Guild[](activeCount);
        
        uint256 index = 0;
        for (uint256 i = 1; i <= totalGuilds; i++) {
            if (guilds[i].active) {
                activeGuilds[index] = guilds[i];
                index++;
            }
        }

        // Simple bubble sort by total points
        for (uint256 i = 0; i < activeGuilds.length; i++) {
            for (uint256 j = i + 1; j < activeGuilds.length; j++) {
                if (activeGuilds[j].totalPoints > activeGuilds[i].totalPoints) {
                    Guild memory temp = activeGuilds[i];
                    activeGuilds[i] = activeGuilds[j];
                    activeGuilds[j] = temp;
                }
            }
        }

        Guild[] memory result = new Guild[](resultSize);
        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = activeGuilds[i];
        }

        return result;
    }

    function getTotalGuilds() external view override returns (uint256) {
        return currentGuildId;
    }

    function getGuildMemberInfo(uint256 guildId, address member) 
        external 
        view 
        returns (GuildMember memory) 
    {
        return guildMembers[guildId][member];
    }

    // Internal Functions
    function _removeMember(uint256 guildId, address member) internal {
        Guild storage guild = guilds[guildId];
        
        // Remove from mapping
        delete guildMembers[guildId][member];
        playerGuild[member] = 0;
        guild.memberCount--;

        // Remove from array
        address[] storage members = guildMemberList[guildId];
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
    }
}

