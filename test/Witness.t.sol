// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Witness.sol";
import "../test/Utilities.sol";

contract WitnessTest is Test {

    Utilities utils;
    Witness public witness;
    address George;
    address Mary;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        George = users[0];
        Mary = users[1];
        witness = new Witness();
    }

    function testUpdateName() public {
        vm.startPrank(George);
        witness.register(Mary, 'George');
        string memory newName = 'John';
        witness.updateName(newName);
        assertEq(witness.names(George), newName);
    }

    event NewCouple(address spouse1, address spouse2, string name1, string name2);

    function testEmitNewCoupleEvent() public {
        vm.startPrank(George);
        witness.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary);
        vm.expectEmit(address(witness));
        emit NewCouple(Mary, George, 'Mary', 'George');
        witness.register(George, 'Mary');
    }

    function testBigamyRevert() public {
        vm.startPrank(George);
        witness.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary);
        witness.register(George, 'Mary');
        address Joseph = utils.createUsers(1)[0];
        vm.expectRevert(bytes("Bigamy is not allowed"));
        witness.register(Joseph, 'Mary');
    }
}
