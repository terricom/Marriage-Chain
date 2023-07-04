// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MarriageChainDelegator.sol";
import "../src/MarriageChainDelegate.sol";
import "../test/Utilities.sol";

contract MarriageChainTest is Test {

    Utilities utils;
    MarriageChainDelegate public marriageChain;
    MarriageChainDelegate public marriageChainProxy;
    MarriageChainDelegator public marriageChainDelegator;
    address George;
    address Mary;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        George = users[0];
        Mary = users[1];
        marriageChain = new MarriageChainDelegate();
        marriageChainDelegator = new MarriageChainDelegator(address(marriageChain));
        marriageChainProxy = MarriageChainDelegate(address(marriageChainDelegator));
    }

    function testUpdateName() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        string memory newName = 'John';
        marriageChainProxy.updateName(newName);
        assertEq(marriageChainProxy.names(George), newName);
    }

    event NewCouple(address spouse1, address spouse2, string name1, string name2);

    function testEmitNewCoupleEvent() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        vm.expectEmit(address(marriageChainProxy));
        emit NewCouple(Mary, George, 'Mary', 'George');
        marriageChainProxy.register(George, 'Mary');
    }

    function testBigamyRevert() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        marriageChainProxy.register(George, 'Mary');
        address Joseph = utils.createUsers(1)[0];
        vm.expectRevert(bytes("Bigamy is not allowed"));
        marriageChainProxy.register(Joseph, 'Mary');
    }

    function testRequiredMarriedBeforeDivorce() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        vm.expectRevert(bytes("You are not married"));
        marriageChainProxy.divorce();
    }

    function testDivorceResetStatus() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        marriageChainProxy.register(George, 'Mary');
        marriageChainProxy.divorce();
        (bool isMarried, ,) = marriageChainProxy.marriageStatus(Mary);
        assertEq(isMarried, false);
    }

    function testDivorceSplitAccount() public {
        vm.startPrank(George, George);
        marriageChainProxy.register(Mary, 'George');
        vm.stopPrank();
        vm.startPrank(Mary, Mary);
        marriageChainProxy.register(George, 'Mary');
        (, ,address account) = marriageChainProxy.marriageStatus(Mary);
        (bool transfer, ) = account.call { value: 10 ether }("");
        assertEq(transfer, true);
        assertEq(account.balance, 10 ether);
        uint256 balanceBefore = Mary.balance;
        marriageChainProxy.divorce();
        uint256 balanceAfter = Mary.balance;
        assertEq(balanceAfter - balanceBefore, 5 ether);
    }
}
