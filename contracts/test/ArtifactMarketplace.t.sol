// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/marketplace/ArtifactMarketplace.sol";
import "../src/tokens/ArtifactNFT.sol";

contract ArtifactMarketplaceTest is Test {
    ArtifactMarketplace public marketplace;
    ArtifactNFT public artifactNFT;
    
    address public owner;
    address public minter;
    address public seller;
    address public buyer;
    
    uint256 public tokenId1;
    uint256 public tokenId2;
    
    function setUp() public {
        owner = address(this);
        minter = makeAddr("minter");
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        
        vm.deal(seller, 10 ether);
        vm.deal(buyer, 10 ether);
        
        artifactNFT = new ArtifactNFT();
        marketplace = new ArtifactMarketplace(address(artifactNFT));
        
        artifactNFT.setMinter(minter);
        
        // Mint NFTs for seller
        vm.startPrank(minter);
        tokenId1 = artifactNFT.mintArtifact(seller, 1, 2, "DeFi", 1);
        tokenId2 = artifactNFT.mintArtifact(seller, 2, 3, "NFTs", 2);
        vm.stopPrank();
    }
    
    function testListArtifact() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        
        assertEq(listingId, 1);
        
        IArtifactMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertEq(listing.tokenId, tokenId1);
        assertEq(listing.seller, seller);
        assertEq(listing.price, 1 ether);
        assertTrue(listing.active);
        vm.stopPrank();
    }
    
    function testCannotListWithoutApproval() public {
        vm.prank(seller);
        vm.expectRevert("ArtifactMarketplace: marketplace not approved");
        marketplace.listArtifact(tokenId1, 1 ether);
    }
    
    function testBuyArtifact() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        vm.stopPrank();
        
        uint256 sellerBalanceBefore = seller.balance;
        
        vm.prank(buyer);
        marketplace.buyArtifact{value: 1 ether}(listingId);
        
        // Check ownership transferred
        assertEq(artifactNFT.ownerOf(tokenId1), buyer);
        
        // Check seller got paid (minus fees)
        uint256 sellerBalanceAfter = seller.balance;
        uint256 platformFee = (1 ether * 2) / 100; // 2%
        uint256 expectedPayment = 1 ether - platformFee;
        
        assertEq(sellerBalanceAfter - sellerBalanceBefore, expectedPayment);
    }
    
    function testRoyaltyPayment() public {
        // Create a secondary owner to test royalty properly
        address secondarySeller = makeAddr("secondarySeller");
        
        // Transfer NFT from seller (original owner) to secondary seller
        vm.prank(seller);
        artifactNFT.transferFrom(seller, secondarySeller, tokenId1);
        
        // Get the original owner (should still be seller)
        IArtifactNFT.ArtifactMetadata memory metadata = artifactNFT.getArtifactDetails(tokenId1);
        address originalOwner = metadata.originalOwner;
        assertEq(originalOwner, seller); // Verify seller is original owner
        
        // Secondary seller lists the NFT
        vm.startPrank(secondarySeller);
        artifactNFT.approve(address(marketplace), tokenId1);
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        vm.stopPrank();
        
        uint256 originalOwnerBalanceBefore = seller.balance;
        
        // Buyer purchases from secondary seller
        vm.prank(buyer);
        marketplace.buyArtifact{value: 1 ether}(listingId);
        
        // Original owner (seller) should get royalty
        uint256 originalOwnerBalanceAfter = seller.balance;
        uint256 royalty = (1 ether * 5) / 100; // 5%
        
        assertEq(originalOwnerBalanceAfter - originalOwnerBalanceBefore, royalty);
    }
    
    function testCancelListing() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        
        marketplace.cancelListing(listingId);
        vm.stopPrank();
        
        IArtifactMarketplace.Listing memory listing = marketplace.getListing(listingId);
        assertFalse(listing.active);
    }
    
    function testOnlySellerCanCancel() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        vm.stopPrank();
        
        vm.prank(buyer);
        vm.expectRevert("ArtifactMarketplace: not seller");
        marketplace.cancelListing(listingId);
    }
    
    function testMakeOffer() public {
        vm.prank(buyer);
        uint256 offerId = marketplace.makeOffer{value: 0.5 ether}(tokenId1, 0.5 ether);
        
        assertEq(offerId, 1);
    }
    
    function testAcceptOffer() public {
        vm.prank(buyer);
        uint256 offerId = marketplace.makeOffer{value: 0.5 ether}(tokenId1, 0.5 ether);
        
        uint256 sellerBalanceBefore = seller.balance;
        
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        marketplace.acceptOffer(offerId);
        vm.stopPrank();
        
        // Check ownership transferred
        assertEq(artifactNFT.ownerOf(tokenId1), buyer);
        
        // Check seller got paid
        uint256 sellerBalanceAfter = seller.balance;
        assertGt(sellerBalanceAfter, sellerBalanceBefore);
    }
    
    function testCancelOffer() public {
        vm.startPrank(buyer);
        uint256 offerId = marketplace.makeOffer{value: 0.5 ether}(tokenId1, 0.5 ether);
        
        uint256 balanceBefore = buyer.balance;
        marketplace.cancelOffer(offerId);
        uint256 balanceAfter = buyer.balance;
        
        // Should get refund
        assertEq(balanceAfter - balanceBefore, 0.5 ether);
        vm.stopPrank();
    }
    
    function testGetActiveListings() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        artifactNFT.approve(address(marketplace), tokenId2);
        
        marketplace.listArtifact(tokenId1, 1 ether);
        marketplace.listArtifact(tokenId2, 2 ether);
        vm.stopPrank();
        
        IArtifactMarketplace.Listing[] memory listings = marketplace.getActiveListings();
        assertEq(listings.length, 2);
    }
    
    function testGetTokenOffers() public {
        vm.startPrank(buyer);
        marketplace.makeOffer{value: 0.5 ether}(tokenId1, 0.5 ether);
        marketplace.makeOffer{value: 0.6 ether}(tokenId1, 0.6 ether);
        vm.stopPrank();
        
        IArtifactMarketplace.Offer[] memory offers = marketplace.getTokenOffers(tokenId1);
        assertEq(offers.length, 2);
    }
    
    function testGetUserListings() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        artifactNFT.approve(address(marketplace), tokenId2);
        
        marketplace.listArtifact(tokenId1, 1 ether);
        marketplace.listArtifact(tokenId2, 2 ether);
        vm.stopPrank();
        
        IArtifactMarketplace.Listing[] memory listings = marketplace.getUserListings(seller);
        assertEq(listings.length, 2);
    }
    
    function testGetFloorPrice() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        artifactNFT.approve(address(marketplace), tokenId2);
        
        marketplace.listArtifact(tokenId1, 2 ether);
        marketplace.listArtifact(tokenId2, 1 ether);
        vm.stopPrank();
        
        uint256 floorPrice = marketplace.getFloorPrice();
        assertEq(floorPrice, 1 ether);
    }
    
    function testCannotBuyWithInsufficientPayment() public {
        vm.startPrank(seller);
        artifactNFT.approve(address(marketplace), tokenId1);
        uint256 listingId = marketplace.listArtifact(tokenId1, 1 ether);
        vm.stopPrank();
        
        vm.prank(buyer);
        vm.expectRevert("ArtifactMarketplace: insufficient payment");
        marketplace.buyArtifact{value: 0.5 ether}(listingId);
    }
}

