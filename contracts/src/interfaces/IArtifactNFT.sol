// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IArtifactNFT {
    struct ArtifactMetadata {
        uint256 tokenId;
        uint256 puzzleId;
        uint256 rarity;
        uint256 mintTime;
        address originalOwner;
        string category;
        uint256 solveRank;
    }

    event ArtifactMinted(address indexed player, uint256 indexed tokenId, uint256 rarity);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event ArtifactBurned(uint256 indexed tokenId);

    function mintArtifact(
        address to,
        uint256 puzzleId,
        uint256 rarity,
        string memory category,
        uint256 solveRank
    ) external returns (uint256);

    function burnArtifact(uint256 tokenId) external;
    function setBaseURI(string memory baseURI) external;

    function getPlayerArtifacts(address player) external view returns (uint256[] memory);
    function getArtifactDetails(uint256 tokenId) external view returns (ArtifactMetadata memory);
    function getArtifactsByRarity(address player, uint256 rarity) external view returns (uint256[] memory);
    function getTotalArtifacts(address player) external view returns (uint256);
    function getRarityCount(address player, uint256 rarity) external view returns (uint256);
    function checkArtifactOwnership(address player, uint256 tokenId) external view returns (bool);
    function getArtifactRank(uint256 tokenId) external view returns (uint256);
    function getTotalMinted() external view returns (uint256);
}

