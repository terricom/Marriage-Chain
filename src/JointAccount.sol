// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Joint Account - A multi-sig contract requires two signatures before transaction
 * @author Terri Yang - @terricom
 */
contract JointAccount {

    using ECDSA for bytes32;

    event ExecutionSuccess(bytes32 txHash);
    event ExecutionFailure(bytes32 txHash);

    address[] public couples;
    mapping(address => bool) public isOwner;

    uint256 public threshold;
    uint256 public nonce;
    uint256 private couplesCount = 2;
    address private marriageChain;

    receive() external payable {}

    constructor(        
        address[2] memory _owners
    ) {
        _setupOwners(_owners);
        marriageChain = msg.sender;
    }

    function _setupOwners(address[2] memory _owners) internal {
        require(threshold == 0, "This account has been initialized.");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && owner != address(this) && !isOwner[owner], "Addresses is invalid or duplicated.");
            couples.push(owner);
            isOwner[owner] = true;
        }
        require(couples.length == couplesCount, "Couples required to have 2 addresses.");
        threshold = couplesCount;
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
        nonce++;
        bool valid = checkSignatures(txHash, signatures);
        require(valid);
        (success, ) = to.call{ value: value }(data);
        require(success , 'Transaction failed :"( ');
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view returns (bool valid) {
        uint256 _threshold = threshold;
        require(_threshold > 0, "This account has not been initialized.");

        require(signatures.length >= _threshold * 65, "Signatures length is not valid.");

        address lastOwner = address(0); 
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            // check signature is valid
            bytes memory signature = abi.encodePacked(r, s, v);
            currentOwner = dataHash.toEthSignedMessageHash().recover(signature);
            require(isOwner[currentOwner], "Signature is not from owners.");
            require(currentOwner > lastOwner, "Signatures are identical.");
            lastOwner = currentOwner;
        }
        return true;
    }
    
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce,
        uint256 chainid
    ) public pure returns (bytes32) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    to,
                    value,
                    keccak256(data),
                    _nonce,
                    chainid
                )
            );
        return safeTxHash;
    }

    function splitAccount() public {
        require(msg.sender == marriageChain, "Only marriage chain can split account");
        address[] memory owners = couples;
        uint amount = address(this).balance / 2;
        address spouse1 = owners[0];
        address spouse2 = owners[1];
        (bool success1, ) = spouse1.call{ value: amount }("");
        (bool success2, ) = spouse2.call{ value: amount }("");
        require(success1 && success2);
        threshold = 0;
    }
}