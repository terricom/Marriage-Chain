// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MarriageChainDelegator.sol";
import "../src/MarriageChainDelegate.sol";

contract MarriageChainScript is Script {
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        MarriageChainDelegate marriageChain = new MarriageChainDelegate();
        MarriageChainDelegator marriageChainDelegator = new MarriageChainDelegator(address(marriageChain));
        MarriageChainDelegate marriageChainProxy = MarriageChainDelegate(address(marriageChainDelegator));
    }
}