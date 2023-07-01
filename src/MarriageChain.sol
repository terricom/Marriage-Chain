// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";

contract MarriageChain is ERC721 {

    mapping(address => MarriageStatus) public marriageStatus;
    mapping(address => string) public names;

    struct MarriageStatus {
        bool isMarried;
        address spouse;
    }

    event NewCouple(address spouse1, address spouse2, string name1, string name2);

    constructor() ERC721("Marriage Certificate", "MC") {}

    modifier checkSpouse(address spouse) {
        require(spouse != msg.sender, "You can't get married with yourself");
        require(spouse != address(0), "Invalid spouse address");
        _;
    }

    function register(address spouse, string calldata name) public payable checkSpouse(spouse) {
        require(msg.sender == tx.origin, "Contract cannot get married!");
        MarriageStatus memory myStatus = marriageStatus[msg.sender];
        MarriageStatus memory spouseStatus = marriageStatus[spouse];
        require(!myStatus.isMarried && !spouseStatus.isMarried, "Bigamy is not allowed");
        myStatus.spouse = spouse;
        updateName(name);
        if (spouseStatus.spouse == msg.sender) {
            myStatus.isMarried = true;
            spouseStatus.isMarried = true;
            marriageStatus[spouse] = spouseStatus;
            mintCertificate(spouse);
            emit NewCouple(msg.sender, spouse, name, names[spouse]);
        }
        marriageStatus[msg.sender] = myStatus;
    }

    function updateName(string calldata name) public {
        names[msg.sender] = name;
    }

    function updateSpouse(address spouse) public checkSpouse(spouse) {
        MarriageStatus memory myStatus = marriageStatus[msg.sender];
        require(!myStatus.isMarried, "You are married! Update spouse is not allowed.");
        myStatus.spouse = spouse;
        marriageStatus[msg.sender] = myStatus;
    }

    function mintCertificate(address spouse) internal {
        _mint(spouse, uint256(uint160(spouse)));
    }

     function tokenURI(uint256 id) public view override returns (string memory) {
        return _buildTokenURI(id);
    }

    function spouseInfo(address spouse) private view returns (string memory) {
        return string(abi.encodePacked(
            '<text x="20" y="300">',
            names[spouse],
            '</text>',
            '<text x="20" y="330" style="font-size:14px;">',
            addressToString(spouse),
            '</text>'
            )
        );
    }

    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        address spouse = marriageStatus[address(uint160(id))].spouse;

        // TODO: Add share account address
        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<?xml version="1.0" encoding="UTF-8"?>',
                        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet">',
                        '<style type="text/css"><![CDATA[text { font-family: monospace; font-size: 21px;} .h1 {font-size: 40px; font-weight: 600;}]]></style>',
                        '<rect width="400" height="400" fill="#ffffff" />',
                        '<text class="h1" x="30" y="70">Certificate of</text>',
                        '<text class="h1" x="95" y="120" >Marriage</text>',
                        unicode'<text x="150" y="275" style="font-size:60px;">💍</text>',
                        '<text x="20" y="180">',
                        names[address(uint160(id))],
                        '</text>',
                        '<text x="20" y="210" style="font-size:14px;">',
                        addressToString(address(uint160(id))),
                        '</text>',
                        spouseInfo(spouse),
                        "</svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Certificate of Marriage", "image":"',
                                image,
                                unicode'", "description": "This NFT marks the certificate of marrage for',
                                names[address(uint160(id))],
                                '(',
                                addressToString(address(uint160(id))),
                                ')&',
                                names[spouse],
                                '(',
                                addressToString(spouse),
                                ')"}'
                            )
                        )
                    )
                )
            );
    }

    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
