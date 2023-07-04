// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MarriageChainStorage {

    address public implementation;
    address public admin;
    mapping(address => MarriageStatus) public marriageStatus;
    mapping(address => string) public names;

    struct MarriageStatus {
        bool isMarried;
        address spouse;
        address jointAccount;
    }
}
