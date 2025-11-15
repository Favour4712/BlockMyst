// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IArtifactNFT.sol";

contract ArtifactNFT is ERC721, ERC721URIStorage, Ownable, IArtifactNFT {
    using Strings for uint256;

    // State variables
    mapping(uint256 => ArtifactMetadata) public artifacts;
    mapping(address => uint256[]) private playerArtifacts;
    mapping(uint256 => uint256) public artifactRarity;
    mapping(address => mapping(uint256 => uint256)) public artifactCount;
    
    uint256 public totalMinted;
    string private _baseURIExtended;
    
    // Address that can mint (PuzzleManager)
    address public minter;
    
    // Crafting System
    mapping(uint256 => bool) public isCrafted; // tokenId => is crafted
    bool public craftingEnabled = true;
    uint256 public constant CRAFT_COST = 3; // Need 3 NFTs of same rarity to craft next tier

    constructor() ERC721("BlockMyst Artifact", "BMYST") Ownable(msg.sender) {
        _baseURIExtended = "ipfs://";
    }

    // Modifiers
    modifier onlyMinter() {
        require(msg.sender == minter, "ArtifactNFT: caller is not the minter");
        _;
    }

    // Admin Functions
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "ArtifactNFT: zero address");
        minter = _minter;
    }

    function setBaseURI(string memory baseURI) external override onlyOwner {
        _baseURIExtended = baseURI;
    }

    function setCraftingEnabled(bool enabled) external onlyOwner {
        craftingEnabled = enabled;
    }

    // Write Functions
    function mintArtifact(
        address to,
        uint256 puzzleId,
        uint256 rarity,
        string memory category,
        uint256 solveRank
    ) external override onlyMinter returns (uint256) {
        require(to != address(0), "ArtifactNFT: mint to zero address");
        require(rarity >= 1 && rarity <= 4, "ArtifactNFT: invalid rarity");

        totalMinted++;
        uint256 tokenId = totalMinted;

        _safeMint(to, tokenId);

        ArtifactMetadata memory metadata = ArtifactMetadata({
            tokenId: tokenId,
            puzzleId: puzzleId,
            rarity: rarity,
            mintTime: block.timestamp,
            originalOwner: to,
            category: category,
            solveRank: solveRank
        });

        artifacts[tokenId] = metadata;
        artifactRarity[tokenId] = rarity;
        playerArtifacts[to].push(tokenId);
        artifactCount[to][rarity]++;

        emit ArtifactMinted(to, tokenId, rarity);

        return tokenId;
    }

    function burnArtifact(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "ArtifactNFT: not token owner");
        
        address owner = ownerOf(tokenId);
        uint256 rarity = artifactRarity[tokenId];
        
        // Remove from player's artifacts array
        uint256[] storage userArtifacts = playerArtifacts[owner];
        for (uint256 i = 0; i < userArtifacts.length; i++) {
            if (userArtifacts[i] == tokenId) {
                userArtifacts[i] = userArtifacts[userArtifacts.length - 1];
                userArtifacts.pop();
                break;
            }
        }
        
        if (artifactCount[owner][rarity] > 0) {
            artifactCount[owner][rarity]--;
        }

        _burn(tokenId);
        
        emit ArtifactBurned(tokenId);
    }

    // Read Functions
    function getPlayerArtifacts(address player) external view override returns (uint256[] memory) {
        return playerArtifacts[player];
    }

    function getArtifactDetails(uint256 tokenId) external view override returns (ArtifactMetadata memory) {
        require(_ownerOf(tokenId) != address(0), "ArtifactNFT: token does not exist");
        return artifacts[tokenId];
    }

    function getArtifactsByRarity(address player, uint256 rarity) 
        external 
        view 
        override 
        returns (uint256[] memory) 
    {
        uint256[] memory allArtifacts = playerArtifacts[player];
        uint256 count = artifactCount[player][rarity];
        uint256[] memory result = new uint256[](count);
        
        uint256 index = 0;
        for (uint256 i = 0; i < allArtifacts.length && index < count; i++) {
            if (artifactRarity[allArtifacts[i]] == rarity) {
                result[index] = allArtifacts[i];
                index++;
            }
        }
        
        return result;
    }

    function getTotalArtifacts(address player) external view override returns (uint256) {
        return playerArtifacts[player].length;
    }

    function getRarityCount(address player, uint256 rarity) external view override returns (uint256) {
        return artifactCount[player][rarity];
    }

    function checkArtifactOwnership(address player, uint256 tokenId) 
        external 
        view 
        override 
        returns (bool) 
    {
        return _ownerOf(tokenId) == player;
    }

    function getArtifactRank(uint256 tokenId) external view override returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "ArtifactNFT: token does not exist");
        return artifacts[tokenId].solveRank;
    }

    function getTotalMinted() external view override returns (uint256) {
        return totalMinted;
    }

    // CRAFTING FUNCTIONS
    function craftArtifact(uint256[] memory tokenIds) external returns (uint256) {
        require(craftingEnabled, "ArtifactNFT: crafting disabled");
        require(tokenIds.length == CRAFT_COST, "ArtifactNFT: need exactly 3 NFTs");
        
        // Verify ownership and same rarity
        uint256 baseRarity = artifactRarity[tokenIds[0]];
        require(baseRarity < 4, "ArtifactNFT: cannot craft legendary");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == msg.sender, "ArtifactNFT: not token owner");
            require(artifactRarity[tokenIds[i]] == baseRarity, "ArtifactNFT: rarity mismatch");
        }
        
        // Burn the 3 NFTs
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
            
            // Update player's artifact tracking
            uint256[] storage userArtifacts = playerArtifacts[msg.sender];
            for (uint256 j = 0; j < userArtifacts.length; j++) {
                if (userArtifacts[j] == tokenIds[i]) {
                    userArtifacts[j] = userArtifacts[userArtifacts.length - 1];
                    userArtifacts.pop();
                    break;
                }
            }
            
            if (artifactCount[msg.sender][baseRarity] > 0) {
                artifactCount[msg.sender][baseRarity]--;
            }
        }
        
        // Mint new higher rarity NFT
        totalMinted++;
        uint256 newTokenId = totalMinted;
        uint256 newRarity = baseRarity + 1;
        
        _safeMint(msg.sender, newTokenId);
        
        // Use first token's metadata as base
        ArtifactMetadata memory baseMetadata = artifacts[tokenIds[0]];
        
        artifacts[newTokenId] = ArtifactMetadata({
            tokenId: newTokenId,
            puzzleId: baseMetadata.puzzleId,
            rarity: newRarity,
            mintTime: block.timestamp,
            originalOwner: msg.sender,
            category: baseMetadata.category,
            solveRank: 0 // Crafted artifacts have no solve rank
        });
        
        artifactRarity[newTokenId] = newRarity;
        isCrafted[newTokenId] = true;
        playerArtifacts[msg.sender].push(newTokenId);
        artifactCount[msg.sender][newRarity]++;
        
        emit ArtifactMinted(msg.sender, newTokenId, newRarity);
        
        return newTokenId;
    }

    function canCraft(address player, uint256 rarity) external view returns (bool) {
        if (!craftingEnabled || rarity >= 4) return false;
        return artifactCount[player][rarity] >= CRAFT_COST;
    }

    function isCraftedArtifact(uint256 tokenId) external view returns (bool) {
        return isCrafted[tokenId];
    }

    // Override functions
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        require(_ownerOf(tokenId) != address(0), "ArtifactNFT: token does not exist");
        
        string memory baseURI = _baseURI();
        ArtifactMetadata memory metadata = artifacts[tokenId];
        
        // Create metadata JSON identifier based on puzzle and rarity
        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, metadata.puzzleId.toString(), "-", metadata.rarity.toString(), ".json"))
            : "";
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    // Track transfers to update player arrays
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        address previousOwner = super._update(to, tokenId, auth);

        // Handle transfer updates (skip on mint/burn)
        if (from != address(0) && to != address(0)) {
            // Remove from old owner's array
            uint256[] storage fromArtifacts = playerArtifacts[from];
            for (uint256 i = 0; i < fromArtifacts.length; i++) {
                if (fromArtifacts[i] == tokenId) {
                    fromArtifacts[i] = fromArtifacts[fromArtifacts.length - 1];
                    fromArtifacts.pop();
                    break;
                }
            }
            
            // Add to new owner's array
            playerArtifacts[to].push(tokenId);
            
            // Update counts
            uint256 rarity = artifactRarity[tokenId];
            if (artifactCount[from][rarity] > 0) {
                artifactCount[from][rarity]--;
            }
            artifactCount[to][rarity]++;
            
            emit ArtifactTransferred(from, to, tokenId);
        }

        return previousOwner;
    }
}

