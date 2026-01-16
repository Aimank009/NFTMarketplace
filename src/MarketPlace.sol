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
    uint256 public constant MAX_FEE = 1000;
    uint256 public accumulatedFees;

    error NotNFTOwner();
    error NotApprovedForMarketPlace();
    error PriceMustBeGreaterThanZero();
    error ListingNotActive();
    error NotTheSeller();
    error InsufficientPayment();
    error NFTAlreadyListed();
    error FeeTooHigh();
    error NoFeesToWithdraw();
    error TransferFailed();

    constructor() Ownable(msg.sender) {}

    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) external override nonReentrant returns (uint256) {
        if (_price == 0) revert PriceMustBeGreaterThanZero();

        IERC721 nft = IERC721(_nftContract);

        if (msg.sender != nft.ownerOf(_tokenId)) revert NotNFTOwner();

        if (getListingId[_nftContract][_tokenId] != 0)
            revert NFTAlreadyListed();

        if (
            nft.getApproved(_tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) revert NotApprovedForMarketPlace();

        uint256 listingId = nextListingId++;

        listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price,
            isActive: true
        });

        getListingId[_nftContract][_tokenId] = listingId;

        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NFTListed(listingId, msg.sender, _nftContract, _tokenId, _price);

        return listingId;
    }

    function buyNFT(uint256 _listingId) external payable override nonReentrant {
        Listing storage listing = listings[_listingId];

        if (!listing.isActive) revert ListingNotActive();

        if (msg.value < listing.price) revert InsufficientPayment();

        uint256 fee = (listing.price * marketPlaceFee) / 10000;

        uint256 sellerAmount = listing.price - fee;

        listing.isActive = false;

        getListingId[listing.nftContract][listing.tokenId] = 0;

        accumulatedFees += fee;

        IERC721(listing.nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        (bool success, ) = payable(listing.seller).call{value: sellerAmount}(
            ""
        );
        if (!success) revert TransferFailed();

        if (msg.value > listing.price) {
            (bool refundSuccess, ) = payable(msg.sender).call{
                value: msg.value - listing.price
            }("");
            if (!refundSuccess) revert TransferFailed();
        }

        emit NFTSold(
            _listingId,
            msg.sender,
            listing.seller,
            listing.nftContract,
            listing.tokenId,
            listing.price,
            fee
        );
    }
}
