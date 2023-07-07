// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title Marriage Chain Storage - A contract stores marriage chain related data
 * @author Terri Yang - @terricom
 */
contract MarriageChainStorage {

    address public implementation;
    address public admin;
    mapping(address => MarriageStatus) public marriageStatus;
    mapping(address => string) public names;

    struct MarriageStatus {
        bool isMarried;
        address spouse;
        address jointAccount;
        uint256 certificate;
    }
}
