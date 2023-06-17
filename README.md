# Marriage-Chain
Get married on blockchain is so easy!
Provide stand-alone marriage services from witness, certificate, joint account and also divorce.

## Description

### Witness contract
Provide a brief overview of the project, including its purpose, goals, and any relevant background information.

- methods
    - register(address with, string name) payable
    - getMarried(address who) return bool
    - getFiance(address who) return address
    - getSpouse(address who) returns address
    - divorce() payable
- process of getting married
    - user1 register
    - user2 register
    - contract check both register
    - new MarriageCertificate NFT
    - new JointAccount
- process of getting divorced
    - user1 divorce
    - user2 divorce
    - burn marriage certificate NFT
    - split joint account

### Marriage certificate NFT

- Content
    - names
    - addresses
    - blocktime

### Joint account (MultiSig wallet)

- methods
    - withdraw
    - split

- Reference
    - https://zhuanlan.zhihu.com/p/47474274?utm_id=0
    - https://etherscan.io/tx/0xc206bb9f30050a2abb95f7e65c6381a9202f5776f0ec633913af1fc0bd0829fe
    - https://etherscan.io/tx/0xe57243c88fb10b9ff9eeab7e51a197830092975339c07c7bcaf685d501c57237
    - https://medium.com/coinmonks/get-married-on-the-blockchain-25091f12399b

## Framework

Describe different components or modules in your project and their responsibilities respectively. This section should highlights the key functionalities or features that each component contributes to the overall project.
Illustrate the overall workflow or process involved in the project.
[Nice to have] You can use flowcharts or diagrams to visualize the sequence of steps or interactions between components.

## Development

Include step-by-step instructions on how to set up and run the project.
.env.example
command example
If this project includes BE or FE, provide instructions for those as well.

## Testing

Explain how to run the tests.
[Nice to have] 80% or more coverage.

## Usage

Explain how to use the project and provide examples or code snippets to demonstrate its usage.