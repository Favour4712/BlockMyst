// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IProgressionManager.sol";

contract ProgressionManager is Ownable, IProgressionManager {
    // Simplified PlayerProgress for storage
    struct StoredPlayerProgress {
        uint256 level;
        uint256 experience;
        uint256 totalExperience;
        uint256 prestigeLevel;
    }

    // State variables
    mapping(address => StoredPlayerProgress) public playerProgress;
    mapping(address => mapping(string => bool)) public unlockedCategories;
    mapping(address => mapping(uint256 => bool)) public unlockedDifficulties;
    mapping(address => mapping(uint256 => bool)) public playerSkills;
    mapping(address => uint256[]) public playerSkillList;
    
    mapping(uint256 => SkillTreeNode) public skillTree;
    uint256 public currentSkillId;
    
    address public puzzleManager;
    
    // Level progression constants
    uint256 public constant BASE_EXPERIENCE = 100;
    uint256 public constant EXPERIENCE_MULTIPLIER = 150; // 1.5x per level
    uint256 public constant PRESTIGE_LEVEL = 50;

    constructor() Ownable(msg.sender) {
        _initializeSkillTree();
    }

    modifier onlyPuzzleManager() {
        require(msg.sender == puzzleManager, "ProgressionManager: not puzzle manager");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "ProgressionManager: zero address");
        puzzleManager = _puzzleManager;
    }

    function createSkill(
        string memory name,
        string memory description,
        uint256 requiredLevel,
        uint256 cost
    ) external onlyOwner returns (uint256) {
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode({
            id: currentSkillId,
            name: name,
            description: description,
            requiredLevel: requiredLevel,
            cost: cost,
            active: true
        });
        return currentSkillId;
    }

    // Write Functions
    function addExperience(address player, uint256 amount) external override onlyPuzzleManager {
        StoredPlayerProgress storage progress = playerProgress[player];
        
        // First time player initialization
        if (progress.level == 0) {
            progress.level = 1;
            unlockedDifficulties[player][1] = true; // Unlock Easy
            unlockedCategories[player]["General"] = true;
            emit CategoryUnlocked(player, "General");
        }
        
        // Add experience
        progress.experience += amount;
        progress.totalExperience += amount;

        emit ExperienceGained(player, amount);

        // Check for level up
        while (progress.experience >= _getExperienceForLevel(progress.level + 1)) {
            progress.experience -= _getExperienceForLevel(progress.level + 1);
            progress.level++;
            
            emit LevelUp(player, progress.level);
            
            // Auto-unlock difficulties based on level
            _checkDifficultyUnlocks(player, progress.level);
        }

        // Check for prestige eligibility
        if (progress.level >= PRESTIGE_LEVEL && progress.prestigeLevel == 0) {
            emit PrestigeUnlocked(player, 1);
        }
    }

    function unlockCategory(address player, string memory category) external override onlyPuzzleManager {
        require(!unlockedCategories[player][category], "ProgressionManager: category already unlocked");
        unlockedCategories[player][category] = true;
        emit CategoryUnlocked(player, category);
    }

    function unlockSkill(uint256 skillId) external override {
        SkillTreeNode memory skill = skillTree[skillId];
        require(skill.active, "ProgressionManager: skill not active");
        require(playerProgress[msg.sender].level >= skill.requiredLevel, "ProgressionManager: level too low");
        require(!playerSkills[msg.sender][skillId], "ProgressionManager: skill already unlocked");

        playerSkills[msg.sender][skillId] = true;
        playerSkillList[msg.sender].push(skillId);

        emit SkillUnlocked(msg.sender, skillId);
    }

    function prestige() external override {
        StoredPlayerProgress storage progress = playerProgress[msg.sender];
        require(progress.level >= PRESTIGE_LEVEL, "ProgressionManager: level too low");

        progress.prestigeLevel++;
        progress.level = 1;
        progress.experience = 0;
        
        // Keep total experience and unlocked categories
        // This is the prestige bonus

        emit PrestigeUnlocked(msg.sender, progress.prestigeLevel);
    }

    // Read Functions
    function getPlayerLevel(address player) external view override returns (uint256) {
        uint256 level = playerProgress[player].level;
        if (level == 0) {
            // New player, return 1 but don't modify state
            return 1;
        }
        return level;
    }

    function getPlayerExperience(address player) 
        external 
        view 
        override 
        returns (uint256 current, uint256 needed) 
    {
        StoredPlayerProgress memory progress = playerProgress[player];
        current = progress.experience;
        needed = _getExperienceForLevel(progress.level + 1);
        return (current, needed);
    }

    function hasUnlockedCategory(address player, string memory category) 
        external 
        view 
        override 
        returns (bool) 
    {
        return unlockedCategories[player][category];
    }

    function hasUnlockedDifficulty(address player, uint256 difficulty) 
        external 
        view 
        override 
        returns (bool) 
    {
        // All players start with Easy unlocked
        if (difficulty == 1) {
            return true;
        }
        return unlockedDifficulties[player][difficulty];
    }

    function getExperienceForNextLevel(address player) external view override returns (uint256) {
        uint256 level = playerProgress[player].level;
        return _getExperienceForLevel(level == 0 ? 2 : level + 1);
    }

    function canAccessPuzzle(address player, uint256 difficulty, string memory category) 
        external 
        view 
        override 
        returns (bool) 
    {
        // Check difficulty (Easy is always unlocked)
        bool difficultyUnlocked = difficulty == 1 || unlockedDifficulties[player][difficulty];
        
        // Check category (General is always accessible for new players)
        bool categoryUnlocked = unlockedCategories[player][category] || 
                               unlockedCategories[player]["General"] ||
                               keccak256(bytes(category)) == keccak256(bytes("General"));
        
        return difficultyUnlocked && categoryUnlocked;
    }

    function getPlayerSkills(address player) external view override returns (uint256[] memory) {
        return playerSkillList[player];
    }

    function getPlayerStats(address player) external view returns (
        uint256 level,
        uint256 experience,
        uint256 totalExperience,
        uint256 prestigeLevel,
        uint256 experienceNeeded
    ) {
        StoredPlayerProgress memory progress = playerProgress[player];
        return (
            progress.level == 0 ? 1 : progress.level,
            progress.experience,
            progress.totalExperience,
            progress.prestigeLevel,
            _getExperienceForLevel(progress.level + 1)
        );
    }

    function hasSkill(address player, uint256 skillId) external view returns (bool) {
        return playerSkills[player][skillId];
    }

    // Internal Functions
    function _getExperienceForLevel(uint256 level) internal pure returns (uint256) {
        if (level <= 1) return 0;
        // Exponential growth: 100, 150, 225, 338, 507, etc.
        return (BASE_EXPERIENCE * (EXPERIENCE_MULTIPLIER ** (level - 2))) / (100 ** (level - 2));
    }

    function _checkDifficultyUnlocks(address player, uint256 level) internal {
        if (level >= 5 && !unlockedDifficulties[player][2]) {
            unlockedDifficulties[player][2] = true; // Medium
        }
        if (level >= 10 && !unlockedDifficulties[player][3]) {
            unlockedDifficulties[player][3] = true; // Hard
        }
        if (level >= 20 && !unlockedDifficulties[player][4]) {
            unlockedDifficulties[player][4] = true; // Expert
        }
    }

    function _initializeSkillTree() internal {
        // Solving Skills
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Quick Thinker", "10% bonus points on speed solves", 3, 100, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Streak Master", "15% bonus on streak rewards", 5, 200, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Efficient Solver", "Reduce hint costs by 25%", 7, 300, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Risk Taker", "20% higher staking multiplier", 10, 500, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "NFT Crafter", "Unlock NFT crafting", 12, 750, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Guild Leader", "Can create guilds", 15, 1000, true);
        
        currentSkillId++;
        skillTree[currentSkillId] = SkillTreeNode(currentSkillId, "Puzzle Creator", "Can create community puzzles", 20, 2000, true);
    }
}

