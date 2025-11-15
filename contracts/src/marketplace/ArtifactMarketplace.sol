// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IArtifactMarketplace.sol";
import "../interfaces/IArtifactNFT.sol";

contract ArtifactMarketplace is Ownable, ReentrancyGuard, IArtifactMarketplace {
    // State variables
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Offer[]) public tokenOffers;
    mapping(uint256 => Offer) public offers;
    mapping(address => uint256[]) public userListings;
    mapping(uint256 => uint256) public tokenToListing; // tokenId => listingId
    
    uint256 public currentListingId;
    uint256 public currentOfferId;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public royaltyPercentage = 5; // 5% to original owner
    
    IArtifactNFT public artifactNFT;

    constructor(address _artifactNFT) Ownable(msg.sender) {
        require(_artifactNFT != address(0), "ArtifactMarketplace: zero address");
        artifactNFT = IArtifactNFT(_artifactNFT);
    }

    // Admin Functions
    function setPlatformFee(uint256 percentage) external onlyOwner {
        require(percentage <= 10, "ArtifactMarketplace: fee too high");
        platformFeePercentage = percentage;
    }

    function setRoyaltyPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 10, "ArtifactMarketplace: royalty too high");
        royaltyPercentage = percentage;
    }

    // Write Functions
    function listArtifact(uint256 tokenId, uint256 price) 
        external 
        override 
        nonReentrant 
        returns (uint256) 
    {
        require(price > 0, "ArtifactMarketplace: price must be > 0");
        require(
            IERC721(address(artifactNFT)).ownerOf(tokenId) == msg.sender,
            "ArtifactMarketplace: not token owner"
        );
        require(
            IERC721(address(artifactNFT)).getApproved(tokenId) == address(this) ||
            IERC721(address(artifactNFT)).isApprovedForAll(msg.sender, address(this)),
            "ArtifactMarketplace: marketplace not approved"
        );
        require(tokenToListing[tokenId] == 0, "ArtifactMarketplace: already listed");

        currentListingId++;
        uint256 listingId = currentListingId;

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true,
            listedAt: block.timestamp
        });

        userListings[msg.sender].push(listingId);
        tokenToListing[tokenId] = listingId;

        emit ArtifactListed(listingId, tokenId, msg.sender, price);
        return listingId;
    }

    function buyArtifact(uint256 listingId) external payable override nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "ArtifactMarketplace: listing not active");
        require(msg.value >= listing.price, "ArtifactMarketplace: insufficient payment");

        listing.active = false;
        tokenToListing[listing.tokenId] = 0;

        // Calculate fees
        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 royaltyFee = 0;
        
        // Get original owner and pay royalty
        IArtifactNFT.ArtifactMetadata memory metadata = artifactNFT.getArtifactDetails(listing.tokenId);
        if (metadata.originalOwner != listing.seller && metadata.originalOwner != address(0)) {
            royaltyFee = (listing.price * royaltyPercentage) / 100;
            (bool royaltySuccess, ) = metadata.originalOwner.call{value: royaltyFee}("");
            require(royaltySuccess, "ArtifactMarketplace: royalty transfer failed");
        }

        uint256 sellerAmount = listing.price - platformFee - royaltyFee;

        // Transfer NFT
        IERC721(address(artifactNFT)).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        // Pay seller
        (bool sellerSuccess, ) = listing.seller.call{value: sellerAmount}("");
        require(sellerSuccess, "ArtifactMarketplace: seller payment failed");

        // Refund excess payment
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = msg.sender.call{value: msg.value - listing.price}("");
            require(refundSuccess, "ArtifactMarketplace: refund failed");
        }

        emit ArtifactSold(listingId, listing.tokenId, msg.sender, listing.price);
    }

    function cancelListing(uint256 listingId) external override nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "ArtifactMarketplace: listing not active");
        require(listing.seller == msg.sender, "ArtifactMarketplace: not seller");

        listing.active = false;
        tokenToListing[listing.tokenId] = 0;

        emit ListingCancelled(listingId);
    }

    function makeOffer(uint256 tokenId, uint256 offerPrice) 
        external 
        payable 
        override 
        nonReentrant 
        returns (uint256)
    {
        require(msg.value >= offerPrice, "ArtifactMarketplace: insufficient payment");
        require(offerPrice > 0, "ArtifactMarketplace: offer must be > 0");
        require(
            IERC721(address(artifactNFT)).ownerOf(tokenId) != msg.sender,
            "ArtifactMarketplace: cannot offer on own token"
        );

        currentOfferId++;
        uint256 offerId = currentOfferId;

        Offer memory newOffer = Offer({
            offerId: offerId,
            tokenId: tokenId,
            buyer: msg.sender,
            offerPrice: offerPrice,
            active: true,
            createdAt: block.timestamp
        });

        offers[offerId] = newOffer;
        tokenOffers[tokenId].push(newOffer);

        emit OfferMade(offerId, tokenId, msg.sender, offerPrice);
        return offerId;
    }

    function acceptOffer(uint256 offerId) external override nonReentrant {
        Offer storage offer = offers[offerId];
        require(offer.active, "ArtifactMarketplace: offer not active");
        require(
            IERC721(address(artifactNFT)).ownerOf(offer.tokenId) == msg.sender,
            "ArtifactMarketplace: not token owner"
        );

        offer.active = false;

        // Calculate fees (same as buy)
        uint256 platformFee = (offer.offerPrice * platformFeePercentage) / 100;
        uint256 royaltyFee = 0;
        
        IArtifactNFT.ArtifactMetadata memory metadata = artifactNFT.getArtifactDetails(offer.tokenId);
        if (metadata.originalOwner != msg.sender && metadata.originalOwner != address(0)) {
            royaltyFee = (offer.offerPrice * royaltyPercentage) / 100;
            (bool royaltySuccess, ) = metadata.originalOwner.call{value: royaltyFee}("");
            require(royaltySuccess, "ArtifactMarketplace: royalty transfer failed");
        }

        uint256 sellerAmount = offer.offerPrice - platformFee - royaltyFee;

        // Cancel listing if exists
        uint256 listingId = tokenToListing[offer.tokenId];
        if (listingId > 0 && listings[listingId].active) {
            listings[listingId].active = false;
            tokenToListing[offer.tokenId] = 0;
        }

        // Transfer NFT
        IERC721(address(artifactNFT)).safeTransferFrom(msg.sender, offer.buyer, offer.tokenId);

        // Pay seller
        (bool sellerSuccess, ) = msg.sender.call{value: sellerAmount}("");
        require(sellerSuccess, "ArtifactMarketplace: seller payment failed");

        emit OfferAccepted(offerId, offer.tokenId);
    }

    function cancelOffer(uint256 offerId) external override nonReentrant {
        Offer storage offer = offers[offerId];
        require(offer.active, "ArtifactMarketplace: offer not active");
        require(offer.buyer == msg.sender, "ArtifactMarketplace: not offer creator");

        offer.active = false;

        // Refund offer amount
        (bool refundSuccess, ) = msg.sender.call{value: offer.offerPrice}("");
        require(refundSuccess, "ArtifactMarketplace: refund failed");

        emit OfferCancelled(offerId);
    }

    // Read Functions
    function getListing(uint256 listingId) external view override returns (Listing memory) {
        return listings[listingId];
    }

    function getActiveListings() external view override returns (Listing[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= currentListingId; i++) {
            if (listings[i].active) {
                count++;
            }
        }

        Listing[] memory result = new Listing[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentListingId; i++) {
            if (listings[i].active) {
                result[index] = listings[i];
                index++;
            }
        }

        return result;
    }

    function getTokenOffers(uint256 tokenId) external view override returns (Offer[] memory) {
        Offer[] memory allOffers = tokenOffers[tokenId];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < allOffers.length; i++) {
            if (allOffers[i].active) {
                activeCount++;
            }
        }

        Offer[] memory activeOffers = new Offer[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allOffers.length; i++) {
            if (allOffers[i].active) {
                activeOffers[index] = allOffers[i];
                index++;
            }
        }

        return activeOffers;
    }

    function getUserListings(address user) external view override returns (Listing[] memory) {
        uint256[] memory listingIds = userListings[user];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < listingIds.length; i++) {
            if (listings[listingIds[i]].active) {
                activeCount++;
            }
        }

        Listing[] memory result = new Listing[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < listingIds.length; i++) {
            if (listings[listingIds[i]].active) {
                result[index] = listings[listingIds[i]];
                index++;
            }
        }

        return result;
    }

    function getFloorPrice() external view returns (uint256) {
        uint256 floor = type(uint256).max;
        
        for (uint256 i = 1; i <= currentListingId; i++) {
            if (listings[i].active && listings[i].price < floor) {
                floor = listings[i].price;
            }
        }
        
        return floor == type(uint256).max ? 0 : floor;
    }

    // Receive function
    receive() external payable {}
}

