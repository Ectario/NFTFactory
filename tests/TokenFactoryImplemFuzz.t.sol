// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../_contracts/TokenFactoryImplem.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TokenFactoryImplemFuzz is Test {
    TokenFactoryImplem nft;
    address owner;
    mapping(address => uint256[]) private userTokens;
    mapping(uint256 => bool) private expectedTokens;

    function setUp() public {
        owner = address(this);

        TokenFactoryImplem implementation = new TokenFactoryImplem();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSignature("initialize()")
        );
        nft = TokenFactoryImplem(address(proxy));
    }

    function testMassMintBurn(uint256 numMints, uint256 numBurns) public {
        numMints = bound(numMints, 0, 1e3); // https://book.getfoundry.sh/cheatcodes/assume 
        require(numMints >= 0 && numMints <= 1000);
        numBurns = bound(numBurns, 0, numMints); // https://book.getfoundry.sh/cheatcodes/assume
        require(numBurns >= 0 && numBurns <= numMints); // Only burn what we minted

        address[] memory users = new address[](numMints);
        
        // mint NFTs to random users
        for (uint256 i = 0; i < numMints; i++) {
            users[i] = vm.addr(i + 1);
            string memory metadataURI = string(abi.encodePacked("ipfs://QmBLABLABLA", vm.toString(i)));

            nft.mintNFT(users[i], metadataURI);

            uint256 tokenId = nft.tokensOfOwner(users[i])[0];
            userTokens[users[i]].push(tokenId);
        }

        // check minting success
        for (uint256 i = 0; i < numMints; i++) {
            uint256[] memory tokens = nft.tokensOfOwner(users[i]);
            assertEq(tokens.length, userTokens[users[i]].length);
        }

        // burn NFTs randomly
        for (uint256 i = 0; i < numBurns; i++) {
            address randomUser = users[i % users.length];
            uint256[] memory tokens = nft.tokensOfOwner(randomUser);

            if (tokens.length > 0) {
                uint256 tokenId = tokens[0];

                vm.prank(randomUser);
                nft.burn(tokenId);

                vm.expectRevert();
                nft.ownerOf(tokenId);

                // check every tokens to be sure

                uint256[] memory updatedTokens = nft.tokensOfOwner(randomUser);
                assertEq(updatedTokens.length, tokens.length - 1);

                for (uint256 k = 1; k < tokens.length; k++) {
                    expectedTokens[tokens[k]] = true;
                }

                for (uint256 j = 0; j < updatedTokens.length; j++) {
                    assertTrue(expectedTokens[updatedTokens[j]], "Remaining token list is incorrect");
                }
            }
        }
    }
}
