// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Witness {

    address owner;
    mapping(address => MarriageStatus) public marriageStatus;
    mapping(address => string) public names;

    struct MarriageStatus {
        bool isMarried;
        address spouse;
    }

    event NewCouple(address spouse1, address spouse2, string name1, string name2);

    constructor() {
        owner = msg.sender;
    }

    function register(address spouse, string calldata name) public {
        MarriageStatus memory myStatus = marriageStatus[msg.sender];
        MarriageStatus memory spouseStatus = marriageStatus[spouse];
        require(!myStatus.isMarried && !spouseStatus.isMarried, "Bigamy is not allowed");
        myStatus.spouse = spouse;
        updateName(name);
        if (spouseStatus.spouse == msg.sender) {
            myStatus.isMarried = true;
            spouseStatus.isMarried = true;
            marriageStatus[spouse] = spouseStatus;
            emit NewCouple(msg.sender, spouse, name, names[spouse]);
        }
        marriageStatus[msg.sender] = myStatus;
    }

    function updateName(string calldata name) public {
        names[msg.sender] = name;
    }

    function updateSpouse(address spouse) public {
        MarriageStatus memory myStatus = marriageStatus[msg.sender];
        require(!myStatus.isMarried, "You are married! Update spouse is not allowed.");
        myStatus.spouse = spouse;
        marriageStatus[msg.sender] = myStatus;
    }
}
