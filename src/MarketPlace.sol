// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMarketPlace.sol";
import "./events/MarketplaceEvents.sol";
contract MarketPlace is
    IMarketPlace,
    IERC721Receiver,
    ReentrancyGuard,
    Ownable,
    MarketPlaceEvents
{
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => mapping(uint256 => uint256)) public getListingId;

    uint256 public nextListingId = 1;
    uint256 public marketPlaceFee = 250;
    uitn256 public constant MAX_FEE = 1000;
    uint256 public accumulatedFees;

    constructor() Ownable(msg.sender) {}
}
