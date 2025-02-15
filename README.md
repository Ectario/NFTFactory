# NFT Factory - Deployment and Upgrade Guide

This repository contains an upgradeable ERC721 NFT contract using Foundry and OpenZeppelin's UUPS Proxy.

## Prerequisites

Ensure you have the following installed:
- **Foundry** ([Installation Guide](https://book.getfoundry.sh/getting-started/installation))
- **Anvil** (included with Foundry)
- **A funded wallet** if deploying on a testnet or mainnet

## Setting Up a Local Environment

### Running a Local Blockchain with Anvil
Anvil provides a local Ethereum blockchain for testing. Start it with:
```sh
anvil
```
By default, it runs on `http://127.0.0.1:8545` and pre-funds test accounts with 10,000 ETH.

### Setting Environment Variables

To simplify deployment, set up environment variables:

```sh
export PRIVATE_KEY=0xYourPrivateKeyHere # Or the private key given by anvil if this is a local testing
export RPC_URL=http://127.0.0.1:8545
```

Alternatively, create a `.env` file and load it:

```sh
source .env
```

## Running Tests

Run all tests:

```sh
forge test
```

Run a specific test:

```sh
forge test --match-test testFunctionName
```

Enable detailed traces:

```sh
forge test -vvv
```

## Deploying Locally

### Deploy the Contract

The deployment script initializes both the contract implementation and the proxy:

```sh
export PRIVATE_KEY=0xYourPrivateKeyHere
forge script scripts/Deploy.s.sol --broadcast --rpc-url $RPC_URL
```

This script will:
- Deploy the implementation contract (`TokenFactoryImplem.sol`).
- Deploy a **UUPS Proxy** that points to the implementation.
- Call the `initialize()` function on the implementation through the proxy.

### Using the Proxy

After deployment you can store the proxy address and for further interaction you can do the following:

```sh
export PROXY_ADDRESS=0xLoggedAddressAfterDeployment
```

Verify the contract is working:

```sh
cast call $PROXY_ADDRESS "getDistributorName()" --rpc-url $RPC_URL
```

## Upgrading the Contract

### How to Modify the Contract

If you want to upgrade the contract, modify the logic in `_contracts/TokenFactoryImplem.sol`.  
Ensure you **do not change the contract's storage layout**.  
For more details on upgradeable contracts and storage compatibility, see OpenZeppelin's guide:  
https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#upgrading

### Running the Upgrade

Deploy the new implementation and upgrade the proxy to point to it:

```sh
export PROXY_ADDRESS=0xLoggedAddressAfterDeployment
export PRIVATE_KEY=0xYourPrivateKeyHere
forge script scripts/Upgrade.s.sol --broadcast --rpc-url $RPC_URL
```

This will:
- Deploy the updated contract (`TokenFactoryImplem.sol`). _NOTE: You can directly modify the TokenFactoryImplem in `_contracts/` and then run the script to upgrade it_
- Upgrade the proxy to use the new implementation.

### Verify the Upgrade

After performing an upgrade, you can confirm that the new implementation is active by checking the contract version. The contract includes a `version()` function that increments automatically with each upgrade.  

```sh
cast call $PROXY_ADDRESS "version()" --rpc-url $RPC_URL
```

Additionally, you can verify that the new logic is in use by calling a function that was modified in the new implementation, this is an example with `getDistributorName`:  

```sh
cast call $PROXY_ADDRESS "getDistributorName()" --rpc-url $RPC_URL
```

If the upgrade was successful, `version()` should return an incremented value, and `getDistributorName()` should reflect any changes made in the upgraded contract.

## Deploying on Mainnet

### Using a Free Public RPC Endpoint

Instead of running Anvil, you can deploy to Polygon mainnet using a public RPC:

```sh
export RPC_URL=https://polygon-rpc.com
```

### Deployment on Mainnet

```sh
forge script scripts/Deploy.s.sol --broadcast --rpc-url $RPC_URL
```

### Upgrading on Mainnet

_after some changes in `_contracts/TokenFactoryImplem.sol`_

```sh
forge script scripts/Upgrade.s.sol --broadcast --rpc-url $RPC_URL
```

### Minting an NFT

To mint a new NFT, call the `mintNFT` function from the contract using the proxy address. This function requires the recipient’s address and the metadata URI of the token:  

```sh
cast send $PROXY_ADDRESS "mintNFT(address,string)" 0xRecipientAddress "ipfs://your-metadata-uri" --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

Only the contract owner can execute this function. After minting, you can verify the token's metadata with:  

```sh
cast call $PROXY_ADDRESS "tokenURI(uint256)" 0 --rpc-url $RPC_URL
```  
Replace `0` with the correct token ID if multiple NFTs exist.

### Retrieving NFTs Owned by an Address

To check which NFTs are owned by a specific address, use the `tokensOfOwner` function. This function returns an array of token IDs belonging to the specified address.  

#### Retrieve All NFTs of an Address

```sh
cast call $PROXY_ADDRESS "tokensOfOwner(address)" 0xUserAddress --rpc-url $RPC_URL
```

This will return an array of token IDs owned by `0xUserAddress`. If the user owns multiple NFTs, you will get something like:  
```
[1, 3, 7, 10]
```
If the array is empty (`[]`), the user does not own any NFTs.

#### Check Metadata of a Specific NFT

Once you have the token ID, you can check its metadata using: 

```sh
cast call $PROXY_ADDRESS "tokenURI(uint256)" 1 --rpc-url $RPC_URL
```

Replace `1` with the actual token ID from the previous step.

#### Check Ownership of a Specific NFT 

To verify the owner of a specific NFT:  

```sh
cast call $PROXY_ADDRESS "ownerOf(uint256)" 1 --rpc-url $RPC_URL
```
This will return the wallet address that owns token ID `1`. \
These commands allow you to track which tokens belong to a specific address and verify their metadata.

## Commands Overview

| Task | Command |
|------|---------|
| Start local blockchain | `anvil` |
| Run tests | `forge test` |
| Deploy contract locally | `export RPC_URL=<RPC_URL> && export PRIVATE_KEY=0xYourPrivateKeyHere && forge script scripts/Deploy.s.sol --broadcast --rpc-url $RPC_URL` |
| Upgrade contract | `export RPC_URL=<RPC_URL> && export PROXY_ADDRESS=0xLoggedAddressAfterDeployment && export PRIVATE_KEY=0xYourPrivateKeyHere && forge script scripts/Upgrade.s.sol --broadcast --rpc-url $RPC_URL` |
| Check implementation version | `cast call $PROXY_ADDRESS "version()" --rpc-url $RPC_URL` |
| Mint an NFT | `cast send $PROXY_ADDRESS "mintNFT(address,string)" 0xRecipientAddress "ipfs://your-metadata-uri" --rpc-url $RPC_URL --private-key $PRIVATE_KEY` |
| Check token metadata | `cast call $PROXY_ADDRESS "tokenURI(uint256)" <TokenID> --rpc-url $RPC_URL` |
| Check all NFTs owned by an address | `cast call $PROXY_ADDRESS "tokensOfOwner(address)" 0xUserAddress --rpc-url $RPC_URL` |
| Check the owner of a specific NFT | `cast call $PROXY_ADDRESS "ownerOf(uint256)" <TokenID> --rpc-url $RPC_URL` |
| Burn an NFT | `cast send $PROXY_ADDRESS "burn(uint256)" <TokenID> --rpc-url $RPC_URL --private-key $PRIVATE_KEY` |