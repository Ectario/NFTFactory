// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TokenFactoryImplem is ERC721URIStorageUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private _nextTokenId;
    uint256 public version;

    function initialize() public initializer {
        __ERC721_init("EctarioToken", "ETK");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Ownable_init(_msgSender());

        version = 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // already checked that it's the owner here
        version += 1;
    }

    function mintNFT(address recipient, string memory metadataURI) public onlyOwner {
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, metadataURI);
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
