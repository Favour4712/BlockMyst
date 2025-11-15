// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IProgressionManager {
    struct PlayerProgress {
        uint256 level;
        uint256 experience;
        uint256 totalExperience;
        uint256 prestigeLevel;
        mapping(string => bool) unlockedCategories;
        mapping(uint256 => bool) unlockedDifficulties;
    }

    struct SkillTreeNode {
        uint256 id;
        string name;
        string description;
        uint256 requiredLevel;
        uint256 cost; // In points
        bool active;
    }

    event LevelUp(address indexed player, uint256 newLevel);
    event PrestigeUnlocked(address indexed player, uint256 prestigeLevel);
    event CategoryUnlocked(address indexed player, string category);
    event SkillUnlocked(address indexed player, uint256 skillId);
    event ExperienceGained(address indexed player, uint256 amount);

    function addExperience(address player, uint256 amount) external;
    function unlockCategory(address player, string memory category) external;
    function unlockSkill(uint256 skillId) external;
    function prestige() external;
    
    function getPlayerLevel(address player) external view returns (uint256);
    function getPlayerExperience(address player) external view returns (uint256, uint256);
    function hasUnlockedCategory(address player, string memory category) external view returns (bool);
    function hasUnlockedDifficulty(address player, uint256 difficulty) external view returns (bool);
    function getExperienceForNextLevel(address player) external view returns (uint256);
    function canAccessPuzzle(address player, uint256 difficulty, string memory category) external view returns (bool);
    function getPlayerSkills(address player) external view returns (uint256[] memory);
    function hasSkill(address player, uint256 skillId) external view returns (bool);
}

