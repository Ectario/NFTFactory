// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../_contracts/TokenFactoryImplem.sol";
import "./TokenFactoryImplem2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TokenFactoryImplemTest is Test {
    TokenFactoryImplem nft;
    address owner = address(this);
    address recipient = address(0xc0ffee);
    address anotherUser = address(0xbeef);

    event NFTMinted(address indexed recipient, uint256 tokenId, string metadataURI);
    event NFTBurned(address indexed owner, uint256 tokenId);

    function setUp() public {
        TokenFactoryImplem implementation = new TokenFactoryImplem();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        nft = TokenFactoryImplem(address(proxy));
    }

    function testMintNFT() public {
        vm.expectEmit(true, true, true, true);
        emit NFTMinted(recipient, 0, "ipfs://QmTestURI");

        nft.mintNFT(recipient, "ipfs://QmTestURI");
        assertEq(nft.ownerOf(0), recipient);
        assertEq(nft.tokenURI(0), "ipfs://QmTestURI");
    }

    function testTokensOfOwnerAfterMint() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");
        uint256[] memory tokens = nft.tokensOfOwner(recipient);
        assertEq(tokens.length, 1);
        assertEq(tokens[0], 0);
    }

    function testTokensOfOwnerAfterBurn() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");
        vm.prank(recipient);
        nft.burn(0);
        
        uint256[] memory tokens = nft.tokensOfOwner(recipient);
        assertEq(tokens.length, 0); // Should be empty after burn
    }

    function testBurnNFT() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");

        vm.expectEmit(true, true, true, true);
        emit NFTBurned(recipient, 0);

        vm.prank(recipient);
        nft.burn(0);
        vm.expectRevert();
        nft.ownerOf(0);
    }

    function testBurnNonExistentToken() public {
        vm.expectRevert();
        nft.burn(999); // Token ID 999 does not exist
    }

    function testBurnByNonOwner() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");
        vm.prank(anotherUser); // Another user tries to burn the NFT
        vm.expectRevert();
        nft.burn(0);
    }

    function testUpgrade() public {
        assertEq(nft.getDistributorName(), "Ectario");
        assertEq(nft.version(), 1);
        TokenFactoryImplem2 newImplementation = new TokenFactoryImplem2();
        nft.upgradeToAndCall(address(newImplementation), "");
        assertEq(nft.getDistributorName(), "Modified by owner");
        assertEq(nft.version(), 2);
    }

    function testUpgradeFail() public {
        assertEq(nft.getDistributorName(), "Ectario");
        TokenFactoryImplem2 newImplementation = new TokenFactoryImplem2();
        vm.prank(recipient);
        vm.expectRevert();
        nft.upgradeToAndCall(address(newImplementation), "");
        assertEq(nft.version(), 1);
    }
    
    function testMintFailByNonOwner() public {
        vm.prank(recipient);
        vm.expectRevert();
        nft.mintNFT(recipient, "ipfs://QmTestURI");
    }

    function testOwner() public view {
        assertEq(nft.owner(), owner);
    }

    function testBurnByNonOwnerDoesNotAffectTrueOwner() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");

        uint256[] memory tokensBefore = nft.tokensOfOwner(recipient);
        assertEq(tokensBefore.length, 1);
        assertEq(tokensBefore[0], 0);

        // Another user tries to burn it (should fail)
        vm.prank(anotherUser);
        vm.expectRevert();
        nft.burn(0);

        uint256[] memory tokensAfter = nft.tokensOfOwner(recipient);
        assertEq(tokensAfter.length, 1);
        assertEq(tokensAfter[0], 0);
    }

    function testInitializeCanOnlyBeCalledOnce() public {
        vm.expectRevert();
        nft.initialize();
    }
}
