// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAchievementManager {
    struct Achievement {
        uint256 id;
        string name;
        string description;
        uint256 rewardPoints;
        string badgeIpfsHash;
        bool repeatable;
        uint256 category; // 0=Solving, 1=Streak, 2=Social, 3=Collection, 4=Speed
        bool active;
    }

    struct PlayerAchievement {
        uint256 achievementId;
        uint256 unlockedAt;
        uint256 count; // For repeatable achievements
    }

    event AchievementCreated(uint256 indexed achievementId, string name, uint256 rewardPoints);
    event AchievementUnlocked(address indexed player, uint256 indexed achievementId, uint256 badgeTokenId);
    event BadgeMinted(address indexed player, uint256 indexed tokenId, uint256 achievementId);

    function createAchievement(
        string memory name,
        string memory description,
        uint256 rewardPoints,
        string memory badgeIpfsHash,
        bool repeatable,
        uint256 category
    ) external returns (uint256);

    function unlockAchievement(address player, uint256 achievementId) external;
    function checkAndUnlock(address player, string memory achievementKey) external;
    
    function getAchievement(uint256 achievementId) external view returns (Achievement memory);
    function getPlayerAchievements(address player) external view returns (PlayerAchievement[] memory);
    function hasAchievement(address player, uint256 achievementId) external view returns (bool);
    function getPlayerBadgeCount(address player) external view returns (uint256);
    function getAllAchievements() external view returns (Achievement[] memory);
    function getAchievementsByCategory(uint256 category) external view returns (Achievement[] memory);
}

