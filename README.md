# NFT Marketplace

A decentralized NFT marketplace smart contract built with Solidity and Foundry. This marketplace enables users to list, buy, and trade ERC721 NFTs with built-in escrow functionality and marketplace fees.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Smart Contract Functions](#smart-contract-functions)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Security](#security)
- [License](#license)

## Overview

This NFT Marketplace implements a trustless trading platform where:

- **Sellers** can list their NFTs at a specified price
- **Buyers** can purchase listed NFTs by paying the asking price
- **Escrow** mechanism holds NFTs securely until purchase
- **Marketplace** collects a configurable fee (default 2.5%) on each sale

### How It Works

```
1. Seller approves marketplace
2. Seller lists NFT
3. NFT held in escrow
4. Buyer pays ETH
5. NFT transferred to buyer
6. ETH (minus fee) sent to seller
```

## Features

| Feature               | Description                                       |
| --------------------- | ------------------------------------------------- |
| List NFTs             | Sellers can list any ERC721 NFT at a custom price |
| Buy NFTs              | Buyers purchase with ETH, automatic fee deduction |
| Cancel Listings       | Sellers can cancel and retrieve their NFTs        |
| Update Price          | Sellers can modify listing prices                 |
| Escrow Pattern        | NFTs held securely in contract until sold         |
| Marketplace Fees      | Configurable fee (max 10%) on sales               |
| Fee Withdrawal        | Owner can withdraw accumulated fees               |
| Reentrancy Protection | Secured against reentrancy attacks                |

## Architecture

```
src/
├── interfaces/
│   └── IMarketPlace.sol      # Interface defining function signatures
├── events/
│   └── MarketplaceEvents.sol # All event definitions
└── MarketPlace.sol           # Main contract implementation

test/
└── MarketPlace.t.sol         # Comprehensive test suite
```

### Contract Inheritance

```solidity
MarketPlace
├── IMarketPlace        (Interface)
├── IERC721Receiver     (Receive NFTs safely)
├── ReentrancyGuard     (Security)
├── Ownable             (Admin functions)
└── MarketPlaceEvents   (Events)
```

## Smart Contract Functions

### Core Functions

| Function                               | Access           | Description                     |
| -------------------------------------- | ---------------- | ------------------------------- |
| `listNFT(nftContract, tokenId, price)` | Public           | List an NFT for sale            |
| `buyNFT(listingId)`                    | Public (payable) | Purchase a listed NFT           |
| `cancelListing(listingId)`             | Seller only      | Cancel listing and retrieve NFT |
| `updatePrice(listingId, newPrice)`     | Seller only      | Update listing price            |
| `getListing(listingId)`                | Public (view)    | Get listing details             |

### Admin Functions

| Function                    | Access     | Description                      |
| --------------------------- | ---------- | -------------------------------- |
| `setMarketplaceFee(newFee)` | Owner only | Update marketplace fee (max 10%) |
| `withdrawFee()`             | Owner only | Withdraw accumulated fees        |

### View Functions

| Function                             | Returns                                                        |
| ------------------------------------ | -------------------------------------------------------------- |
| `listings(listingId)`                | Listing struct (seller, nftContract, tokenId, price, isActive) |
| `getListingId(nftContract, tokenId)` | Listing ID for a specific NFT                                  |
| `marketPlaceFee()`                   | Current fee in basis points                                    |
| `accumulatedFees()`                  | Total fees available for withdrawal                            |
| `MAX_FEE()`                          | Maximum allowed fee (1000 = 10%)                               |

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/Aimank009/NFTMarketplace.git
cd NFTMarketplace

# Install dependencies
forge install

# Build the project
forge build
```

## Usage

### Listing an NFT

```solidity
// 1. Approve the marketplace to transfer your NFT
nft.approve(marketplaceAddress, tokenId);

// 2. List the NFT
uint256 listingId = marketplace.listNFT(
    nftContractAddress,
    tokenId,
    1 ether  // price in wei
);
```

### Buying an NFT

```solidity
// Send ETH equal to or greater than the listing price
marketplace.buyNFT{value: 1 ether}(listingId);
```

### Cancelling a Listing

```solidity
// Only the seller can cancel
marketplace.cancelListing(listingId);
```

### Updating Price

```solidity
// Only the seller can update
marketplace.updatePrice(listingId, 2 ether);
```

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_ListNFT

# Generate gas report
forge test --gas-report
```

### Test Coverage

| Category        | Tests        |
| --------------- | ------------ |
| Listing         | 4 tests      |
| Buying          | 3 tests      |
| Cancelling      | 2 tests      |
| Price Updates   | 2 tests      |
| Fee Management  | 4 tests      |
| ERC721 Receiver | 1 test       |
| **Total**       | **17 tests** |

## Security

### Security Features

1. **ReentrancyGuard** - Prevents reentrancy attacks on all state-changing functions
2. **CEI Pattern** - Checks-Effects-Interactions pattern followed
3. **Custom Errors** - Gas-efficient error handling
4. **Access Control** - Owner-only functions for sensitive operations
5. **Max Fee Limit** - Fee cannot exceed 10% (hardcoded constant)
6. **Safe Transfers** - Uses `safeTransferFrom` for NFT transfers

### Custom Errors

```solidity
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
```

## Fee Structure

- **Default Fee**: 250 basis points (2.5%)
- **Maximum Fee**: 1000 basis points (10%)
- **Calculation**: `fee = (price * marketplaceFee) / 10000`

### Example

```
NFT Price: 1 ETH
Fee (2.5%): 0.025 ETH
Seller Receives: 0.975 ETH
```

## Events

| Event                   | When Emitted           |
| ----------------------- | ---------------------- |
| `NFTListed`             | NFT is listed for sale |
| `NFTSold`               | NFT is purchased       |
| `ListingCancelled`      | Listing is cancelled   |
| `PriceUpdated`          | Price is changed       |
| `MarketplaceFeeUpdated` | Fee percentage changes |
| `FeesWithdrawn`         | Owner withdraws fees   |

## License

This project is licensed under the MIT License.

---

Built with Solidity and Foundry
