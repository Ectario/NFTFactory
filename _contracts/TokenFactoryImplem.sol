// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenFactoryImplem is ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private _nextTokenId;
    uint256 public version;

    mapping(address => uint256[]) private _ownedTokens; // Track NFTs per owner

    event NFTMinted(address indexed recipient, uint256 tokenId, string metadataURI);
    event NFTBurned(address indexed owner, uint256 tokenId);

    function initialize() public initializer {
        __ERC721_init("EctarioToken", "ETK");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init(_msgSender());

        version = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        version += 1;
    }

    function mintNFT(address recipient, string memory metadataURI) public onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, metadataURI);

        _ownedTokens[recipient].push(tokenId); // Track ownership
        emit NFTMinted(recipient, tokenId, metadataURI);
    }

    function burn(uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        // Remove the token ID from the owner's list
        _removeTokenFromOwnerList(owner, tokenId);

        // Call ERC721BurnableUpgradeable's burn function
        super.burn(tokenId);

        emit NFTBurned(owner, tokenId);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function _removeTokenFromOwnerList(address owner, uint256 tokenId) internal {
        uint256 length = _ownedTokens[owner].length;
        for (uint256 i = 0; i < length; i++) {
            if (_ownedTokens[owner][i] == tokenId) {
                // Swap the token with the last one, then pop the last one
                _ownedTokens[owner][i] = _ownedTokens[owner][length - 1];
                _ownedTokens[owner].pop();
                break;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getDistributorName() external pure returns (string memory) {
        return "Ectario";
    }
}
