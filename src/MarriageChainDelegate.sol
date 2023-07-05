// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "./JointAccount.sol";
import "./MarriageChainStorage.sol";

contract MarriageChainDelegate is MarriageChainStorage, ERC721 {

    event NewCouple(address spouse1, address spouse2, string name1, string name2);
    event Divorce(address spouse1, address spouse2, string name1, string name2);

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
        bool registerSuccess = spouseStatus.spouse == msg.sender;
        if (registerSuccess) {
            myStatus.isMarried = true;
            spouseStatus.isMarried = true;

            address[2] memory couples = [msg.sender, spouse];
            JointAccount account = new JointAccount(couples);
            myStatus.jointAccount = address(account);
            spouseStatus.jointAccount = address(account);

            myStatus.certificate = uint256(uint160(spouse));
            spouseStatus.certificate = uint256(uint160(spouse));

            marriageStatus[spouse] = spouseStatus;
        }
        marriageStatus[msg.sender] = myStatus;
        if (registerSuccess) {
            mintCertificate(spouse);
            emit NewCouple(msg.sender, spouse, name, names[spouse]);
        }
    }

    function divorce() public {
        MarriageStatus memory myStatus = marriageStatus[msg.sender];
        require(myStatus.isMarried, "You are not married");
        JointAccount(payable(myStatus.jointAccount)).splitAccount();
        _burn(myStatus.certificate);
        marriageStatus[msg.sender] = MarriageStatus(false, address(0), address(0), 0);
        marriageStatus[myStatus.spouse] = MarriageStatus(false, address(0), address(0), 0);
        emit Divorce(msg.sender, myStatus.spouse, names[msg.sender], names[myStatus.spouse]);
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
            unicode'<text x="20" y="250" style="font-size:30px;">💍</text>',
            '<text x="60" y="250">',
            names[spouse],
            '</text>',
            '<text x="20" y="280" style="font-size:14px;">',
            addressToString(spouse),
            '</text>'
            )
        );
    }

    function accountInfo(address account) private pure returns (string memory) {
        return string(abi.encodePacked(
            unicode'<text x="20" y="330" style="font-size:30px;">💰</text>',
            '<text x="60" y="330">Joint account</text>',
            '<text x="20" y="360" style="font-size:14px;">',
            addressToString(account),
            '</text>'
            )
        );
    }

    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        MarriageStatus memory status = marriageStatus[address(uint160(id))];
        address spouse = status.spouse;

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
                        unicode'<text x="20" y="170" style="font-size:30px;">💍</text>',
                        '<text x="60" y="170">',
                        names[address(uint160(id))],
                        '</text>',
                        '<text x="20" y="200" style="font-size:14px;">',
                        addressToString(address(uint160(id))),
                        '</text>',
                        spouseInfo(spouse),
                        accountInfo(status.jointAccount),
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
                                unicode'", "description": "This NFT marks the certificate of marrage for ',
                                names[address(uint160(id))],
                                '(',
                                addressToString(address(uint160(id))),
                                ') & ',
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
