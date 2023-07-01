// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MarriageChain.sol";
import "../test/Utilities.sol";

contract MarriageChainTest is Test {

    Utilities utils;
    MarriageChain public marriageChain;
    address George;
    address Mary;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        George = users[0];
        Mary = users[1];
        marriageChain = new MarriageChain();
    }

    function testUpdateName() public {
        vm.startPrank(George, George);
        marriageChain.register(Mary, 'George');
        string memory newName = 'John';
        marriageChain.updateName(newName);
        assertEq(marriageChain.names(George), newName);
    }

    event NewCouple(address spouse1, address spouse2, string name1, string name2);

    function testEmitNewCoupleEvent() public {
        vm.startPrank(George, George);
        marriageChain.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        vm.expectEmit(address(marriageChain));
        emit NewCouple(Mary, George, 'Mary', 'George');
        marriageChain.register(George, 'Mary');
    }

    function testBigamyRevert() public {
        vm.startPrank(George, George);
        marriageChain.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        marriageChain.register(George, 'Mary');
        address Joseph = utils.createUsers(1)[0];
        vm.expectRevert(bytes("Bigamy is not allowed"));
        marriageChain.register(Joseph, 'Mary');
    }
}
