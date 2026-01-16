//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMarketPlace {
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external returns (uint256 listingId);

    function buyNFT(uint256 listingId) external payable;
    function cancelListing(uint256 listingId) external;
    function updatePrice(uint256 listingId, uint256 newPrice) external;
    function getListing(
        uint256 listingId
    )
        external
        view
        returns (
            address seller,
            address nftContract,
            uint256 price,
            uint256 tokenId,
            bool isActive
        );
}
