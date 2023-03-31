// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract RealEstateAgencyV1 is ERC1155Upgradeable, OwnableUpgradeable {
    
    struct Property {
        uint256 price;
        address owner;
    }
    
    mapping(uint256 => Property) public properties;
    mapping(uint256 => mapping(uint256 => string)) public ipfsHash;
    mapping(address => uint256) public ownerRevenue;
    mapping(uint256 => uint256) public totalPropertyTransactions;
    
    uint256 public totalProperties;
    uint256 public agencyFees;
    uint256 public agencyFeesTotal;

    function initialize(uint256 _agencyFees) external initializer {
        __ERC1155_init("");
        __Ownable_init();
        agencyFees = _agencyFees;
        totalProperties = 0; // initialize to 0
        agencyFeesTotal = 0; // initialize to 0
    }

    function setAgencyFees(uint256 _agencyFees) external onlyOwner {
        agencyFees = _agencyFees;
    }

    function mintProperty(uint256 _price) external payable {
        require(_price >= 1 ether, "Minimum 1 ether");

        require(msg.value == (_price * agencyFees) / 10000, "Incorrect mint price");
        
        uint256 _propertyId = totalProperties;

        properties[_propertyId].price = _price;
        properties[_propertyId].owner = msg.sender;

        agencyFeesTotal += msg.value;
        totalProperties++; // increment the total properties count
    }

    function buyProperty(uint256 _id) external payable {
        require(msg.value == properties[_id].price, "Incorrect buying price");
        require(msg.sender != properties[_id].owner, "You already are the owner");
        
        address propertyOwner = properties[_id].owner;
        uint256 currentSubId = totalPropertyTransactions[_id];
        // Increment owner revenue to the property price
        ownerRevenue[propertyOwner] += properties[_id].price;
        
        _mint(msg.sender, _id, 1, "");
        ipfsHash[_id][currentSubId] = "";

        totalPropertyTransactions[_id] += 1;

        // Set new owner
        properties[_id].owner = msg.sender;
    }

    function setIpfsHash(uint256 tokenId, uint256 subId, string memory hash) public onlyOwner {
        ipfsHash[tokenId][subId] = hash;
    }

    function tokenURI(uint256 tokenId, uint256 subId) public view returns (string memory) {
        return ipfsHash[tokenId][subId];
    }

    function withdrawRevenue(uint256 _amount) public {
        require(ownerRevenue[msg.sender] >= _amount, "Don't have enough funds to withdraw");

        payable(msg.sender).transfer(_amount);

        ownerRevenue[msg.sender] -= _amount;
    }

    function withdrawFees() external onlyOwner {
        uint256 amountToWithdraw = agencyFeesTotal;
        agencyFeesTotal = 0;
        payable(msg.sender).transfer(amountToWithdraw);
    }
}
