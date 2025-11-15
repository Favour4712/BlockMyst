// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReferralManager {
    struct ReferralData {
        address referrer;
        uint256 referralCount;
        uint256 totalEarnings;
        uint256 joinedAt;
    }

    event PlayerReferred(address indexed referrer, address indexed referred);
    event ReferralRewardPaid(address indexed referrer, address indexed referred, uint256 amount);
    event ReferralMilestone(address indexed referrer, uint256 count);

    function registerReferral(address referred, address referrer) external;
    function payReferralReward(address referrer, uint256 amount) external;
    
    function getReferrer(address player) external view returns (address);
    function getReferralCount(address referrer) external view returns (uint256);
    function getReferralData(address player) external view returns (ReferralData memory);
    function getTotalEarnings(address referrer) external view returns (uint256);
    function getReferralTree(address referrer) external view returns (address[] memory);
    function isReferred(address player) external view returns (bool);
}

