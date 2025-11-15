// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/tokens/ArtifactNFT.sol";

contract ArtifactNFTCraftingTest is Test {
    ArtifactNFT public artifactNFT;

    address public owner;
    address public minter;
    address public player1;

    function setUp() public {
        owner = address(this);
        minter = makeAddr("minter");
        player1 = makeAddr("player1");

        artifactNFT = new ArtifactNFT();
        artifactNFT.setMinter(minter);
    }

    function testCraftArtifact() public {
        // Mint 3 Common NFTs (rarity 1)
        vm.startPrank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1);
        uint256 token2 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 2);
        uint256 token3 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 3);
        vm.stopPrank();

        assertEq(artifactNFT.getRarityCount(player1, 1), 3);

        // Craft them into a Rare
        vm.prank(player1);
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = token1;
        tokenIds[1] = token2;
        tokenIds[2] = token3;

        uint256 craftedToken = artifactNFT.craftArtifact(tokenIds);

        // Check old tokens are burned
        assertEq(artifactNFT.getRarityCount(player1, 1), 0);

        // Check new token exists and is Rare (rarity 2)
        assertEq(artifactNFT.getRarityCount(player1, 2), 1);
        assertTrue(artifactNFT.isCraftedArtifact(craftedToken));

        IArtifactNFT.ArtifactMetadata memory metadata = artifactNFT
            .getArtifactDetails(craftedToken);
        assertEq(metadata.rarity, 2);
    }

    function testCannotCraftWithWrongNumber() public {
        vm.prank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = token1;

        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: need exactly 3 NFTs");
        artifactNFT.craftArtifact(tokenIds);
    }

    function testCannotCraftDifferentRarities() public {
        vm.startPrank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1); // Common
        uint256 token2 = artifactNFT.mintArtifact(player1, 1, 2, "DeFi", 2); // Rare
        uint256 token3 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 3); // Common
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = token1;
        tokenIds[1] = token2;
        tokenIds[2] = token3;

        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: rarity mismatch");
        artifactNFT.craftArtifact(tokenIds);
    }

    function testCannotCraftLegendary() public {
        vm.startPrank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player1, 1, 4, "DeFi", 1); // Legendary
        uint256 token2 = artifactNFT.mintArtifact(player1, 1, 4, "DeFi", 2);
        uint256 token3 = artifactNFT.mintArtifact(player1, 1, 4, "DeFi", 3);
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = token1;
        tokenIds[1] = token2;
        tokenIds[2] = token3;

        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: cannot craft legendary");
        artifactNFT.craftArtifact(tokenIds);
    }

    function testCannotCraftOthersNFTs() public {
        address player2 = makeAddr("player2");

        vm.startPrank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player2, 1, 1, "DeFi", 1);
        uint256 token2 = artifactNFT.mintArtifact(player2, 1, 1, "DeFi", 2);
        uint256 token3 = artifactNFT.mintArtifact(player2, 1, 1, "DeFi", 3);
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = token1;
        tokenIds[1] = token2;
        tokenIds[2] = token3;

        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: not token owner");
        artifactNFT.craftArtifact(tokenIds);
    }

    function testCanCraft() public {
        vm.startPrank(minter);
        artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1);
        artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 2);
        artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 3);
        vm.stopPrank();

        assertTrue(artifactNFT.canCraft(player1, 1));
        assertFalse(artifactNFT.canCraft(player1, 2)); // Don't have 3 Rares
    }

    function testCraftingCanBeDisabled() public {
        artifactNFT.setCraftingEnabled(false);

        vm.startPrank(minter);
        uint256 token1 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 1);
        uint256 token2 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 2);
        uint256 token3 = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", 3);
        vm.stopPrank();

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = token1;
        tokenIds[1] = token2;
        tokenIds[2] = token3;

        vm.prank(player1);
        vm.expectRevert("ArtifactNFT: crafting disabled");
        artifactNFT.craftArtifact(tokenIds);
    }

    function testFullCraftingChain() public {
        // Mint 9 Commons (rarity 1)
        vm.startPrank(minter);
        uint256[] memory commonIds = new uint256[](9);
        for (uint256 i = 0; i < 9; i++) {
            commonIds[i] = artifactNFT.mintArtifact(player1, 1, 1, "DeFi", i + 1);
        }
        vm.stopPrank();

        assertEq(artifactNFT.getRarityCount(player1, 1), 9);

        // First craft: 3 Commons -> 1 Rare
        vm.startPrank(player1);
        uint256[] memory batch1 = new uint256[](3);
        batch1[0] = commonIds[0];
        batch1[1] = commonIds[1];
        batch1[2] = commonIds[2];
        uint256 rare1 = artifactNFT.craftArtifact(batch1);
        
        // Second craft: 3 Commons -> 1 Rare
        uint256[] memory batch2 = new uint256[](3);
        batch2[0] = commonIds[3];
        batch2[1] = commonIds[4];
        batch2[2] = commonIds[5];
        uint256 rare2 = artifactNFT.craftArtifact(batch2);
        
        // Third craft: 3 Commons -> 1 Rare
        uint256[] memory batch3 = new uint256[](3);
        batch3[0] = commonIds[6];
        batch3[1] = commonIds[7];
        batch3[2] = commonIds[8];
        uint256 rare3 = artifactNFT.craftArtifact(batch3);

        // Should have 3 Rares now (rarity 2)
        assertEq(artifactNFT.getRarityCount(player1, 2), 3);
        assertEq(artifactNFT.getRarityCount(player1, 1), 0);

        // Verify all rares have same rarity
        IArtifactNFT.ArtifactMetadata memory meta1 = artifactNFT.getArtifactDetails(rare1);
        IArtifactNFT.ArtifactMetadata memory meta2 = artifactNFT.getArtifactDetails(rare2);
        IArtifactNFT.ArtifactMetadata memory meta3 = artifactNFT.getArtifactDetails(rare3);
        assertEq(meta1.rarity, 2);
        assertEq(meta2.rarity, 2);
        assertEq(meta3.rarity, 2);

        // Craft 3 Rares -> 1 Epic
        uint256[] memory rareTokens = new uint256[](3);
        rareTokens[0] = rare1;
        rareTokens[1] = rare2;
        rareTokens[2] = rare3;
        artifactNFT.craftArtifact(rareTokens);
        
        vm.stopPrank();

        // Should have 1 Epic (rarity 3)
        assertEq(artifactNFT.getRarityCount(player1, 3), 1);
        assertEq(artifactNFT.getRarityCount(player1, 2), 0);
    }
}
