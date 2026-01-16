//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract MarketPlaceEvents {
    event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    event NFTSold(
        uint256 indexed listingId,
        address indexed buyer,
        address seller,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 fee
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId
    );

    event PriceUpdated(
        uint256 indexed listingId,
        uint256 oldPrice,
        uint256 newPrice
    );

    event MarketplaceFeeUpdated(uint256 oldFee, uint256 newFee);

    event FeesWithdrawn(address indexed owner, uint256 amount);
}
