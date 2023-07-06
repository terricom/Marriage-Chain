// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../src/JointAccount.sol";

contract JointAccountTest is Test {

    using ECDSA for bytes32;

    JointAccount jointAccount;
    uint256 internal GeorgePrivateKey = 0x01;
    uint256 internal MaryPrivateKey = 0x02;
    uint256 internal JosephPrivateKey = 0x03;
    address George;
    address Mary;
    address Joseph;

    function setUp() public {
        George = vm.addr(GeorgePrivateKey);
        vm.deal(George, 100 ether);
        Mary = vm.addr(MaryPrivateKey);
        vm.deal(Mary, 100 ether);
        jointAccount = new JointAccount([George, Mary]);
        Joseph = vm.addr(JosephPrivateKey);
        vm.deal(Joseph, 100 ether);
    }

    function testOwnerCorrectness() public {
        assertEq(jointAccount.isOwner(George), true);
        assertEq(jointAccount.isOwner(Mary), true);
    }

    event ExecutionSuccess(bytes32 txHash);

    function testExecuteTransactionSuccess() public {
        vm.startPrank(George);
        uint256 sendAmount = 10 ether;
        (bool transfer, ) = address(jointAccount).call { value: sendAmount }("");
        assertEq(transfer, true);

        bytes32 data = jointAccount.encodeTransactionData(George, sendAmount, bytes(""), 0, block.chainid);
        bytes32 digest = data.toEthSignedMessageHash();

        // George sign transaction
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(GeorgePrivateKey, digest);
        bytes memory signature1 = abi.encodePacked(r1, s1, v1);
        vm.stopPrank();
        
        // Mary sign transaction
        vm.startPrank(Mary);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(MaryPrivateKey, digest);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);
        uint256 balanceBefore = George.balance;

        // assert emit ExecutionSuccess
        vm.expectEmit(address(jointAccount));
        emit ExecutionSuccess(data);
        jointAccount.execTransaction(George, sendAmount, bytes(""), George > Mary ? bytes.concat(signature2, signature1) : bytes.concat(signature1, signature2));
        uint256 balanceAfter = George.balance;
        
        // assert balance diff after transaction
        assertEq(balanceAfter - balanceBefore, sendAmount);
    }

    function testExecuteTransactionFailureForDuplicateSignature() public {
        vm.startPrank(George);
        uint256 sendAmount = 10 ether;

        bytes32 data = jointAccount.encodeTransactionData(George, sendAmount, bytes(""), 0, block.chainid);
        bytes32 digest = data.toEthSignedMessageHash();

        // George sign transaction
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(GeorgePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        vm.expectRevert(bytes("Signatures are identical."));
        // Send duplicated signatures
        jointAccount.execTransaction(George, sendAmount, bytes(""), bytes.concat(signature, signature));
    }

    function testExecuteTransactionFailureForWrongSignature() public {
        vm.startPrank(George);
        uint256 sendAmount = 10 ether;

        bytes32 data = jointAccount.encodeTransactionData(George, sendAmount, bytes(""), 0, block.chainid);
        bytes32 digest = data.toEthSignedMessageHash();

        // George sign transaction
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(GeorgePrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.stopPrank();
        vm.startPrank(Joseph);
        // Joseph sign transaction
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(JosephPrivateKey, digest);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        vm.expectRevert(bytes("Signature is not from owners."));
        jointAccount.execTransaction(George, sendAmount, bytes(""), George > Joseph ? bytes.concat(signature2, signature) : bytes.concat(signature, signature2));
    }

    function testSplitAccount() public {
        vm.startPrank(George);
        uint256 sendAmount = 10 ether;
        (bool transfer, ) = address(jointAccount).call { value: sendAmount }("");
        assertEq(transfer, true);
        vm.stopPrank();

        uint256 balanceBefore = George.balance;
        jointAccount.splitAccount();

        uint256 balanceAfter = George.balance;
        // assert balance diff after split account call
        assertEq(balanceAfter - balanceBefore, sendAmount / 2);
    }
}