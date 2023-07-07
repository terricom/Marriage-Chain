# Marriage-Chain

## Description
Get married on blockchain is so easy!!!
Provide stand-alone marriage related services from register, get marriage certificate, mantain joint account, and also divorce incase needed.
- register
- marriage certificate NFT
- create joint account
- divorce

<img decoding="async" src="https://github.com/terricom/Marriage-Chain/assets/50873556/9fea7694-5668-4aa3-a723-e1c1af2ab3a9" width="50%">

## Framework
### Marriage Chain contract
This contract is for couples to `rigister`, and there will be `Marriage Certificate NFT` after registration completed.

### Joint Account contract
This contract is `multi-sig wallet` for couples to mantain joint account, every transaction requires 2 signatures.

- register flow
![register](https://github.com/terricom/Marriage-Chain/assets/50873556/c8f6e767-5840-4a9c-a230-7e6487f9ec3d)

- divorce flow
![divorce](https://github.com/terricom/Marriage-Chain/assets/50873556/2ba35a6c-f6e9-45ef-ad3c-7bdf3a924ac5)

## Development
Clone this repository, install foundry dependencies, and build the source code:
```bash
git clone git@github.com:terricom/Marriage-Chain.git
cd ~/Marriage-Chain
forge install
forge build
forge test
```

## Testing
### MarriageChain.t.sol
Test MarriageChain for register and divorce flow.
- testBigamyRevert()
- testDivorceResetStatus()
- testDivorceSplitAccount()
- testEmitNewCoupleEvent()
- testGetMarriedAgain()
- testRequiredMarriedBeforeDivorce()
- testUpdateName() 

### JointAccount.t.sol
Test JointAccount for execute transaction and split account.
- testExecuteTransactionFailureForDuplicateSignature()
- testExecuteTransactionFailureForWrongSignature()
- testExecuteTransactionSuccess()
- testOwnerCorrectness()
- testSplitAccount()

## Usage
Try marriage contract in https://sepolia.etherscan.io/address/0x25e4243a75ec46bb0122c208e653973d91fd7d8f#writeProxyContract
- connect to web3: Connect to available wallet
- select `Write as Proxy` tab
- `register` input spouse address and name
- wait for yout spouse to `register` your address
- check the minted certificate NFT in https://testnets.opensea.io/collection/unidentified-contract-41918
- execute transaction requires 2 signatures
- `divorce` with spouse and get half of joint account