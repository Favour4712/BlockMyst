// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../interfaces/IAchievementManager.sol";

contract AchievementManager is ERC721, Ownable, IAchievementManager {
    // State variables
    mapping(uint256 => Achievement) public achievements;
    mapping(address => mapping(uint256 => PlayerAchievement)) public playerAchievements;
    mapping(address => uint256[]) private playerAchievementIds;
    mapping(string => uint256) public achievementKeyToId; // "first_solve" => 1
    
    uint256 public currentAchievementId;
    uint256 public currentBadgeTokenId;
    
    mapping(address => bool) public authorizedCallers; // PuzzleManager, etc can unlock achievements
    
    string private _baseURIExtended;

    constructor() ERC721("BlockMyst Badge", "BADGE") Ownable(msg.sender) {
        _baseURIExtended = "ipfs://";
        _initializeDefaultAchievements();
    }

    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender] || msg.sender == owner(), "AchievementManager: not authorized");
        _;
    }

    // Admin Functions
    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        authorizedCallers[caller] = authorized;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    // Write Functions
    function createAchievement(
        string memory name,
        string memory description,
        uint256 rewardPoints,
        string memory badgeIpfsHash,
        bool repeatable,
        uint256 category
    ) external override onlyOwner returns (uint256) {
        currentAchievementId++;
        uint256 achievementId = currentAchievementId;

        achievements[achievementId] = Achievement({
            id: achievementId,
            name: name,
            description: description,
            rewardPoints: rewardPoints,
            badgeIpfsHash: badgeIpfsHash,
            repeatable: repeatable,
            category: category,
            active: true
        });

        emit AchievementCreated(achievementId, name, rewardPoints);
        return achievementId;
    }

    function registerAchievementKey(string memory key, uint256 achievementId) external onlyOwner {
        achievementKeyToId[key] = achievementId;
    }

    function unlockAchievement(address player, uint256 achievementId) public override onlyAuthorized {
        Achievement memory achievement = achievements[achievementId];
        require(achievement.active, "AchievementManager: achievement not active");

        PlayerAchievement storage playerAch = playerAchievements[player][achievementId];

        if (!achievement.repeatable && playerAch.unlockedAt > 0) {
            return; // Already unlocked, skip
        }

        if (playerAch.unlockedAt == 0) {
            // First time unlocking
            playerAch.achievementId = achievementId;
            playerAch.unlockedAt = block.timestamp;
            playerAch.count = 1;
            playerAchievementIds[player].push(achievementId);
        } else {
            // Repeatable achievement
            playerAch.count++;
        }

        // Mint badge NFT
        currentBadgeTokenId++;
        _safeMint(player, currentBadgeTokenId);

        emit AchievementUnlocked(player, achievementId, currentBadgeTokenId);
        emit BadgeMinted(player, currentBadgeTokenId, achievementId);
    }

    function checkAndUnlock(address player, string memory achievementKey) external override onlyAuthorized {
        uint256 achievementId = achievementKeyToId[achievementKey];
        if (achievementId > 0) {
            unlockAchievement(player, achievementId);
        }
    }

    // Read Functions
    function getAchievement(uint256 achievementId) external view override returns (Achievement memory) {
        return achievements[achievementId];
    }

    function getPlayerAchievements(address player) external view override returns (PlayerAchievement[] memory) {
        uint256[] memory ids = playerAchievementIds[player];
        PlayerAchievement[] memory result = new PlayerAchievement[](ids.length);
        
        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = playerAchievements[player][ids[i]];
        }
        
        return result;
    }

    function hasAchievement(address player, uint256 achievementId) external view override returns (bool) {
        return playerAchievements[player][achievementId].unlockedAt > 0;
    }

    function getPlayerBadgeCount(address player) external view override returns (uint256) {
        return playerAchievementIds[player].length;
    }

    function getAllAchievements() external view override returns (Achievement[] memory) {
        Achievement[] memory result = new Achievement[](currentAchievementId);
        for (uint256 i = 1; i <= currentAchievementId; i++) {
            result[i - 1] = achievements[i];
        }
        return result;
    }

    function getAchievementsByCategory(uint256 category) external view override returns (Achievement[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentAchievementId; i++) {
            if (achievements[i].category == category && achievements[i].active) {
                count++;
            }
        }

        Achievement[] memory result = new Achievement[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentAchievementId; i++) {
            if (achievements[i].category == category && achievements[i].active) {
                result[index] = achievements[i];
                index++;
            }
        }

        return result;
    }

    // Internal Functions
    function _initializeDefaultAchievements() internal {
        // Solving Achievements (Category 0)
        _createDefaultAchievement("First Blood", "Solve your first puzzle", 100, "badge_first_solve", false, 0, "first_solve");
        _createDefaultAchievement("Puzzle Master", "Solve 100 puzzles", 1000, "badge_100_solves", false, 0, "hundred_solves");
        _createDefaultAchievement("Legend", "Solve 1000 puzzles", 10000, "badge_1000_solves", false, 0, "thousand_solves");
        
        // Streak Achievements (Category 1)
        _createDefaultAchievement("Perfect Week", "7 day streak", 500, "badge_week_streak", true, 1, "week_streak");
        _createDefaultAchievement("Month Champion", "30 day streak", 5000, "badge_month_streak", true, 1, "month_streak");
        _createDefaultAchievement("Unstoppable", "100 day streak", 25000, "badge_hundred_streak", false, 1, "hundred_streak");
        
        // Speed Achievements (Category 4)
        _createDefaultAchievement("Speed Demon", "Solve in under 60 seconds", 300, "badge_speed", true, 4, "speed_demon");
        _createDefaultAchievement("Flash", "Solve in under 30 seconds", 1000, "badge_flash", true, 4, "flash_solve");
        
        // Social Achievements (Category 2)
        _createDefaultAchievement("Recruiter", "Refer 10 friends", 2000, "badge_recruiter", false, 2, "ten_referrals");
        _createDefaultAchievement("Influencer", "Refer 50 friends", 10000, "badge_influencer", false, 2, "fifty_referrals");
        
        // Collection Achievements (Category 3)
        _createDefaultAchievement("Collector", "Own 50 NFTs", 1500, "badge_collector", false, 3, "fifty_nfts");
        _createDefaultAchievement("Legendary Hunter", "Own 10 Legendary NFTs", 5000, "badge_legendary_hunter", false, 3, "ten_legendaries");
    }

    function _createDefaultAchievement(
        string memory name,
        string memory description,
        uint256 rewardPoints,
        string memory badgeIpfsHash,
        bool repeatable,
        uint256 category,
        string memory key
    ) internal {
        currentAchievementId++;
        achievements[currentAchievementId] = Achievement({
            id: currentAchievementId,
            name: name,
            description: description,
            rewardPoints: rewardPoints,
            badgeIpfsHash: badgeIpfsHash,
            repeatable: repeatable,
            category: category,
            active: true
        });
        achievementKeyToId[key] = currentAchievementId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "AchievementManager: token does not exist");
        return string(abi.encodePacked(_baseURI(), "badge-", Strings.toString(tokenId), ".json"));
    }
}

