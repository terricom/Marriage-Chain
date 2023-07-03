// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract JointAccount {
    event ExecutionSuccess(bytes32 txHash);
    event ExecutionFailure(bytes32 txHash);

    address[] public couples;
    mapping(address => bool) public isOwner;

    uint256 public threshold;
    uint256 public nonce;
    uint256 private couplesCount = 2;

    receive() external payable {}

    constructor(        
        address[2] memory _owners
    ) {
        _setupOwners(_owners);
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
        checkSignatures(txHash, signatures);
        (success, ) = to.call{ value: value }(data);
        require(success , 'Transaction failed :"( ');
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
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
            currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v, r, s);
            require(currentOwner > lastOwner && isOwner[currentOwner], "Signatures are identical or not from owners.");
            lastOwner = currentOwner;
        }
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
}