// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IReferralManager.sol";
import "../interfaces/IAchievementManager.sol";

contract ReferralManager is Ownable, ReentrancyGuard, IReferralManager {
    // State variables
    mapping(address => ReferralData) public referralData;
    mapping(address => address[]) public referralTree; // referrer => referred addresses
    
    uint256 public referralRewardPercentage = 5; // 5% of referred player earnings
    uint256 public constant MAX_REFERRAL_PERCENTAGE = 20;
    
    address public puzzleManager;
    IAchievementManager public achievementManager;

    constructor() Ownable(msg.sender) {}

    modifier onlyPuzzleManager() {
        require(msg.sender == puzzleManager, "ReferralManager: not puzzle manager");
        _;
    }

    // Admin Functions
    function setPuzzleManager(address _puzzleManager) external onlyOwner {
        require(_puzzleManager != address(0), "ReferralManager: zero address");
        puzzleManager = _puzzleManager;
    }

    function setAchievementManager(address _achievementManager) external onlyOwner {
        require(_achievementManager != address(0), "ReferralManager: zero address");
        achievementManager = IAchievementManager(_achievementManager);
    }

    function setReferralRewardPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= MAX_REFERRAL_PERCENTAGE, "ReferralManager: percentage too high");
        referralRewardPercentage = percentage;
    }

    // Write Functions
    function registerReferral(address referred, address referrer) external override {
        require(referred != address(0), "ReferralManager: zero address referred");
        require(referrer != address(0), "ReferralManager: zero address referrer");
        require(referred != referrer, "ReferralManager: cannot refer self");
        require(referralData[referred].referrer == address(0), "ReferralManager: already referred");
        require(referralData[referred].joinedAt == 0, "ReferralManager: player already registered");

        // Register referral
        referralData[referred].referrer = referrer;
        referralData[referred].joinedAt = block.timestamp;
        
        referralData[referrer].referralCount++;
        referralTree[referrer].push(referred);

        emit PlayerReferred(referrer, referred);

        // Check for referral milestones and unlock achievements
        uint256 count = referralData[referrer].referralCount;
        if (count % 10 == 0) {
            emit ReferralMilestone(referrer, count);
            
            // Unlock achievements
            if (address(achievementManager) != address(0)) {
                if (count == 10) {
                    achievementManager.checkAndUnlock(referrer, "ten_referrals");
                } else if (count == 50) {
                    achievementManager.checkAndUnlock(referrer, "fifty_referrals");
                } else if (count == 100) {
                    achievementManager.checkAndUnlock(referrer, "hundred_referrals");
                }
            }
        }
    }

    function payReferralReward(address referrer, uint256 amount) 
        external 
        override 
        onlyPuzzleManager 
        nonReentrant 
    {
        require(referrer != address(0), "ReferralManager: zero address");
        require(amount > 0, "ReferralManager: zero amount");

        uint256 reward = (amount * referralRewardPercentage) / 100;
        referralData[referrer].totalEarnings += reward;

        (bool success, ) = referrer.call{value: reward}("");
        require(success, "ReferralManager: transfer failed");

        emit ReferralRewardPaid(referrer, msg.sender, reward);
    }

    // Read Functions
    function getReferrer(address player) external view override returns (address) {
        return referralData[player].referrer;
    }

    function getReferralCount(address referrer) external view override returns (uint256) {
        return referralData[referrer].referralCount;
    }

    function getReferralData(address player) external view override returns (ReferralData memory) {
        return referralData[player];
    }

    function getTotalEarnings(address referrer) external view override returns (uint256) {
        return referralData[referrer].totalEarnings;
    }

    function getReferralTree(address referrer) external view override returns (address[] memory) {
        return referralTree[referrer];
    }

    function isReferred(address player) external view override returns (bool) {
        return referralData[player].referrer != address(0);
    }

    function getReferralReward(uint256 amount) external view returns (uint256) {
        return (amount * referralRewardPercentage) / 100;
    }

    // Receive function
    receive() external payable {}
}

