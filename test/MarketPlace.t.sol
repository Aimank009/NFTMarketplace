// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MarketPlace.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721 {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to) external returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId);
        return tokenId;
    }
}

contract MarketPlaceTest is Test {
    MarketPlace public marketplace;
    MockNFT public nft;

    address public owner = address(1);
    address public seller = address(2);
    address public buyer = address(3);

    uint256 public constant LISTING_PRICE = 1 ether;

    function setUp() public {
        vm.prank(owner);
        marketplace = new MarketPlace();

        nft = new MockNFT();

        vm.deal(seller, 10 ether);
        vm.deal(buyer, 10 ether);
    }

    function test_ListNFT() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        assertEq(listingId, 1);
        assertEq(nft.ownerOf(tokenId), address(marketplace));

        (
            address listedSeller,
            address listedNft,
            uint256 listedTokenId,
            uint256 listedPrice,
            bool isActive
        ) = marketplace.getListing(listingId);

        assertEq(listedSeller, seller);
        assertEq(listedNft, address(nft));
        assertEq(listedTokenId, tokenId);
        assertEq(listedPrice, LISTING_PRICE);
        assertTrue(isActive);
    }

    function test_ListNFT_RevertIfNotOwner() public {
        uint256 tokenId = nft.mint(seller);

        vm.prank(buyer);
        vm.expectRevert(MarketPlace.NotNFTOwner.selector);
        marketplace.listNFT(address(nft), tokenId, LISTING_PRICE);
    }

    function test_ListNFT_RevertIfNotApproved() public {
        uint256 tokenId = nft.mint(seller);

        vm.prank(seller);
        vm.expectRevert(MarketPlace.NotApprovedForMarketPlace.selector);
        marketplace.listNFT(address(nft), tokenId, LISTING_PRICE);
    }

    function test_ListNFT_RevertIfPriceZero() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        vm.expectRevert(MarketPlace.PriceMustBeGreaterThanZero.selector);
        marketplace.listNFT(address(nft), tokenId, 0);
        vm.stopPrank();
    }

    function test_BuyNFT() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        marketplace.buyNFT{value: LISTING_PRICE}(listingId);

        assertEq(nft.ownerOf(tokenId), buyer);

        uint256 fee = (LISTING_PRICE * 250) / 10000;
        uint256 expectedSellerAmount = LISTING_PRICE - fee;
        assertEq(seller.balance, sellerBalanceBefore + expectedSellerAmount);

        assertEq(marketplace.accumulatedFees(), fee);

        (, , , , bool isActive) = marketplace.getListing(listingId);
        assertFalse(isActive);
    }

    function test_BuyNFT_RevertIfInsufficientPayment() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert(MarketPlace.InsufficientPayment.selector);
        marketplace.buyNFT{value: 0.5 ether}(listingId);
    }

    function test_BuyNFT_RefundsExcess() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        uint256 buyerBalanceBefore = buyer.balance;
        uint256 overpayment = 0.5 ether;

        vm.prank(buyer);
        marketplace.buyNFT{value: LISTING_PRICE + overpayment}(listingId);

        uint256 fee = (LISTING_PRICE * 250) / 10000;
        uint256 expectedSpent = LISTING_PRICE;
        assertEq(buyer.balance, buyerBalanceBefore - expectedSpent);
    }

    function test_CancelListing() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );

        marketplace.cancelListing(listingId);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), seller);

        (, , , , bool isActive) = marketplace.getListing(listingId);
        assertFalse(isActive);
    }

    function test_CancelListing_RevertIfNotSeller() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        vm.prank(buyer);
        vm.expectRevert(MarketPlace.NotTheSeller.selector);
        marketplace.cancelListing(listingId);
    }

    function test_UpdatePrice() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );

        uint256 newPrice = 2 ether;
        marketplace.updatePrice(listingId, newPrice);
        vm.stopPrank();

        (, , , uint256 listedPrice, ) = marketplace.getListing(listingId);
        assertEq(listedPrice, newPrice);
    }

    function test_UpdatePrice_RevertIfZero() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );

        vm.expectRevert(MarketPlace.PriceMustBeGreaterThanZero.selector);
        marketplace.updatePrice(listingId, 0);
        vm.stopPrank();
    }

    function test_SetMarketplaceFee() public {
        uint256 newFee = 500;

        vm.prank(owner);
        marketplace.setMarketplaceFee(newFee);

        assertEq(marketplace.marketPlaceFee(), newFee);
    }

    function test_SetMarketplaceFee_RevertIfTooHigh() public {
        vm.prank(owner);
        vm.expectRevert(MarketPlace.FeeTooHigh.selector);
        marketplace.setMarketplaceFee(1001);
    }

    function test_SetMarketplaceFee_RevertIfNotOwner() public {
        vm.prank(seller);
        vm.expectRevert();
        marketplace.setMarketplaceFee(500);
    }

    function test_WithdrawFees() public {
        uint256 tokenId = nft.mint(seller);

        vm.startPrank(seller);
        nft.approve(address(marketplace), tokenId);
        uint256 listingId = marketplace.listNFT(
            address(nft),
            tokenId,
            LISTING_PRICE
        );
        vm.stopPrank();

        vm.prank(buyer);
        marketplace.buyNFT{value: LISTING_PRICE}(listingId);

        uint256 fee = marketplace.accumulatedFees();
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        marketplace.withdrawFee();

        assertEq(owner.balance, ownerBalanceBefore + fee);
        assertEq(marketplace.accumulatedFees(), 0);
    }

    function test_WithdrawFees_RevertIfNoFees() public {
        vm.prank(owner);
        vm.expectRevert(MarketPlace.NoFeesToWithdraw.selector);
        marketplace.withdrawFee();
    }

    function test_OnERC721Received() public {
        bytes4 expectedSelector = IERC721Receiver.onERC721Received.selector;
        bytes4 result = marketplace.onERC721Received(
            address(0),
            address(0),
            0,
            ""
        );
        assertEq(result, expectedSelector);
    }
}
