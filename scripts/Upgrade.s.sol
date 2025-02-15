// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../_contracts/TokenFactoryImplem.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Upgrade is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        TokenFactoryImplem newImplementation = new TokenFactoryImplem();
        UUPSUpgradeable(proxyAddress).upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();
    }
}
