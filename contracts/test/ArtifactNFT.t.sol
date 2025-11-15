// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/ArtifactNFT.sol";

contract ArtifactNFTTest is Test {
    ArtifactNFT public artifactNFT;
    
    address public owner;
    address public minter;
    address public player1;
    address public player2;
    
    event ArtifactMinted(address indexed player, uint256 indexed tokenId, uint256 rarity);
    event ArtifactBurned(uint256 indexed tokenId);
    
    function setUp() public {
        owner = address(this);
        minter = makeAddr("minter");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        
        artifactNFT = new ArtifactNFT();
        artifactNFT.setMinter(minter);
    }
    
    function testMintArtifact() public {
        vm.prank(minter);
        vm.expectEmit(true, true, true, true);
        emit ArtifactMinted(player1, 1, 2);
        
        uint256 tokenId = artifactNFT.mintArtifact(
            player1,
            1, // puzzleId
            2, // rarity (Rare)
            "DeFi",
            5 // solveRank
        );
        
        assertEq(tokenId, 1);
        assertEq(artifactNFT.ownerOf(tokenId), player1);
        assertEq(artifactNFT.totalMinted(), 1);
        
        IArtifactNFT.ArtifactMetadata memory metadata = artifactNFT.getArtifactDetails(tokenId);
        assertEq(metadata.tokenId, 1);
        assertEq(metadata.puzzleId, 1);
        assertEq(metadata.rarity, 2);
        assertEq(metadata.originalOwner, player1);
        assertEq(metadata.solveRank, 5);
    }
    
    function testOnlyMinterCanMint() public {
        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: caller is not the minter");
        artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 1);
    }
    
    function testGetPlayerArtifacts() public {
        vm.startPrank(minter);
        
        // Mint 3 artifacts for player1
        artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1);
        artifactNFT.mintArtifact(player1, 2, 2, "NFTs", 2);
        artifactNFT.mintArtifact(player1, 3, 3, "DeFi", 3);
        
        vm.stopPrank();
        
        uint256[] memory artifacts = artifactNFT.getPlayerArtifacts(player1);
        assertEq(artifacts.length, 3);
        assertEq(artifactNFT.getTotalArtifacts(player1), 3);
    }
    
    function testGetArtifactsByRarity() public {
        vm.startPrank(minter);
        
        // Mint artifacts with different rarities
        artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1); // Common
        artifactNFT.mintArtifact(player1, 2, 2, "NFTs", 2); // Rare
        artifactNFT.mintArtifact(player1, 3, 2, "DeFi", 3); // Rare
        artifactNFT.mintArtifact(player1, 4, 3, "Web3", 4); // Epic
        
        vm.stopPrank();
        
        uint256[] memory rareArtifacts = artifactNFT.getArtifactsByRarity(player1, 2);
        assertEq(rareArtifacts.length, 2);
        assertEq(artifactNFT.getRarityCount(player1, 2), 2);
        assertEq(artifactNFT.getRarityCount(player1, 3), 1);
    }
    
    function testBurnArtifact() public {
        vm.prank(minter);
        uint256 tokenId = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 1);
        
        assertEq(artifactNFT.getTotalArtifacts(player1), 1);
        
        vm.prank(player1);
        vm.expectEmit(true, true, true, true);
        emit ArtifactBurned(tokenId);
        
        artifactNFT.burnArtifact(tokenId);
        
        assertEq(artifactNFT.getTotalArtifacts(player1), 0);
        
        vm.expectRevert();
        artifactNFT.ownerOf(tokenId);
    }
    
    function testTransferArtifact() public {
        vm.prank(minter);
        uint256 tokenId = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 1);
        
        assertEq(artifactNFT.getTotalArtifacts(player1), 1);
        assertEq(artifactNFT.getTotalArtifacts(player2), 0);
        
        vm.prank(player1);
        artifactNFT.transferFrom(player1, player2, tokenId);
        
        assertEq(artifactNFT.ownerOf(tokenId), player2);
        assertEq(artifactNFT.getTotalArtifacts(player1), 0);
        assertEq(artifactNFT.getTotalArtifacts(player2), 1);
        
        // Check rarity counts updated
        assertEq(artifactNFT.getRarityCount(player1, 2), 0);
        assertEq(artifactNFT.getRarityCount(player2, 2), 1);
    }
    
    function testSetBaseURI() public {
        string memory newBaseURI = "ipfs://NewHash/";
        artifactNFT.setBaseURI(newBaseURI);
        
        vm.prank(minter);
        uint256 tokenId = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 1);
        
        string memory uri = artifactNFT.tokenURI(tokenId);
        assertTrue(bytes(uri).length > 0);
    }
    
    function testCheckArtifactOwnership() public {
        vm.prank(minter);
        uint256 tokenId = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 1);
        
        assertTrue(artifactNFT.checkArtifactOwnership(player1, tokenId));
        assertFalse(artifactNFT.checkArtifactOwnership(player2, tokenId));
    }
    
    function testGetArtifactRank() public {
        vm.prank(minter);
        uint256 tokenId = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 5);
        
        assertEq(artifactNFT.getArtifactRank(tokenId), 5);
    }
}

