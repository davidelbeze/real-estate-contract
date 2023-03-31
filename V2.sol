// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract RealEstateAgencyV2 is ERC1155Upgradeable, OwnableUpgradeable {
    // Property mapping
        // id to price
    mapping(uint256 => uint256) public propertyPrice;
        // id to owner to owner shares
    mapping(uint256 => mapping(address => uint256)) public ownerShares;
        // id to owner to "is owner shares are for sell" 
    mapping(uint256 => mapping(address => uint256)) public ownerSharesForSale;
        
    // Transctions mapping
        // Property ID to transaction Id to IPFS hash
    mapping(uint256 => mapping(uint256 => string)) public ipfsHash;

    // General mapping
        // Owner to his revenues
    mapping(address => uint256) public ownerRevenue;
        // Property ID to total transactions
    mapping(uint256 => uint256) public totalPropertyTransactions;
    
    uint256 public totalProperties;
    uint256 public agencyFees;
    uint256 public agencyFeesTotal;

    function initialize(uint256 _agencyFees) external initializer {
        __ERC1155_init("");
        __Ownable_init();
        agencyFees = _agencyFees;
        totalProperties = 0;
        agencyFeesTotal = 0;
    }

    function setAgencyFees(uint256 _agencyFees) external onlyOwner {
        agencyFees = _agencyFees;
    }

    function mintProperty(uint256 _price) external payable {
        require(_price >= 1 ether, "Minimum 1 ether");

        require(msg.value == (_price * agencyFees) / 10000, "Incorrect mint price");
        
        // Get current property id from totalProperties
        uint256 propertyId = totalProperties;

        // Init property price and owner shares
        propertyPrice[propertyId] = _price;
        ownerShares[propertyId][msg.sender] = 100;

        // Increment agency fees
        agencyFeesTotal += msg.value;
        
        totalProperties++;
    }


    function buySharesFrom(uint256 _id, uint256 _shares, address _seller) external payable {
        // Check if owner has enough shares to sell
        require(ownerShares[_id][_seller] >= _shares, "Not enough owned shares");
        // Check if seller has accepted to sell his shares
        require(ownerSharesForSale[_id][_seller] >= _shares, "Share owner is not selling that shares amount");

        uint256 sharePrice = propertyPrice[_id] * _shares / 100;
        require(msg.value == sharePrice, "Wrong amount for buying shares");

        uint256 currentSubId = totalPropertyTransactions[_id];

        // Set metadata - currently empty
        ipfsHash[_id][currentSubId] = "";

        // Mint a NFT receipt for transaction
        _mint(msg.sender, _id, 1, "");

        // Transfer shares ownership
        ownerShares[_id][_seller] -= _shares;
        ownerShares[_id][msg.sender] += _shares;

        // Increment seller revenue
        ownerRevenue[_seller] += msg.value;

        // Increment transactions of property
        totalPropertyTransactions[_id] += 1;
    }

    function setShareOwnerSelling(uint256 _id, uint256 _amount) public {
        // If owner has enough shares to sell, set owner shares for sale 
        require(ownerShares[_id][msg.sender] >= _amount, "Doesn't have enough share to sell");
        
        ownerSharesForSale[_id][msg.sender] = _amount;
    }
    
    function setIpfsHash(uint256 tokenId, uint256 subId, string memory hash) public onlyOwner {
        // Metadata for NFT Receipt. Currently empty
        ipfsHash[tokenId][subId] = hash;
    }

    function tokenURI(uint256 tokenId, uint256 subId) public view returns (string memory) {
        // Get metadata for transaction
        return ipfsHash[tokenId][subId];
    }

    function withdrawRevenue(uint256 _amount) public {
        // Check if owner has enough funds
        require(ownerRevenue[msg.sender] >= _amount, "Don't have enough funds to withdraw");

        // Decrement owner revenue
        ownerRevenue[msg.sender] -= _amount;
        
        // Transfer fund to owner
        payable(msg.sender).transfer(_amount);

    }

    function withdrawFees() external onlyOwner {
        uint256 amountToWithdraw = agencyFeesTotal;
        // Reset agency fees to 0
        agencyFeesTotal = 0;

        // Transfer fees to owner
        payable(msg.sender).transfer(amountToWithdraw);
    }
}
