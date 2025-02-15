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

    function setUp() public {
        TokenFactoryImplem implementation = new TokenFactoryImplem();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        nft = TokenFactoryImplem(address(proxy));
    }

    function testMintNFT() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");
        assertEq(nft.ownerOf(0), recipient);
        assertEq(nft.tokenURI(0), "ipfs://QmTestURI");
    }

    function testBurnNFT() public {
        nft.mintNFT(recipient, "ipfs://QmTestURI");
        vm.prank(recipient);
        nft.burn(0);
        vm.expectRevert();
        nft.ownerOf(0);
    }

    function testUpgrade() public {
        assertEq(nft.getDistributorName(), "Ectario");
        TokenFactoryImplem2 newImplementation = new TokenFactoryImplem2();
        nft.upgradeToAndCall(address(newImplementation), "");
        assertEq(nft.getDistributorName(), "Modified by owner");
    }

    function testUpgradeFail() public {
        assertEq(nft.getDistributorName(), "Ectario");
        TokenFactoryImplem2 newImplementation = new TokenFactoryImplem2();
        vm.prank(recipient);
        vm.expectRevert();
        nft.upgradeToAndCall(address(newImplementation), "");
    }

    function testMintFail() public {
        vm.prank(recipient);
        vm.expectRevert();
        nft.mintNFT(recipient, "ipfs://QmTestURI");
    }

    function testOwner() public view {
        assertEq(nft.owner(), owner);
    }
}
