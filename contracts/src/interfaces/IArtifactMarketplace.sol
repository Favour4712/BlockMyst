// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IArtifactMarketplace {
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
        uint256 listedAt;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 offerPrice;
        bool active;
        uint256 createdAt;
    }

    event ArtifactListed(uint256 indexed listingId, uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtifactSold(uint256 indexed listingId, uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed listingId);
    event OfferMade(uint256 indexed offerId, uint256 indexed tokenId, address indexed buyer, uint256 offerPrice);
    event OfferAccepted(uint256 indexed offerId, uint256 indexed tokenId);
    event OfferCancelled(uint256 indexed offerId);

    function listArtifact(uint256 tokenId, uint256 price) external returns (uint256);
    function buyArtifact(uint256 listingId) external payable;
    function cancelListing(uint256 listingId) external;
    function makeOffer(uint256 tokenId, uint256 offerPrice) external payable returns (uint256);
    function acceptOffer(uint256 offerId) external;
    function cancelOffer(uint256 offerId) external;
    
    function getListing(uint256 listingId) external view returns (Listing memory);
    function getActiveListings() external view returns (Listing[] memory);
    function getTokenOffers(uint256 tokenId) external view returns (Offer[] memory);
    function getUserListings(address user) external view returns (Listing[] memory);
}

