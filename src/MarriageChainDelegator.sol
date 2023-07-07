// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./MarriageChainStorage.sol";

/**
 * @title Marriage Chain Delegator - A proxy contract for marriage chain
 * @author Terri Yang - @terricom
 */
contract MarriageChainDelegator is MarriageChainStorage {

  constructor(address _implementation){
    admin = msg.sender;
    implementation = _implementation;
  }

  fallback() external payable {
    require(msg.sender != admin, "Transparant Proxy Only");
    (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    
    assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
  }

  function upgrade(address newImplementation) external {
    if (msg.sender != admin) revert();
    implementation = newImplementation;
  }

  receive() external payable {}
}