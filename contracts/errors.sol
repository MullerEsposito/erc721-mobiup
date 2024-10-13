//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./structs/NFT.sol";

error SupplyUnavailable();
error SupplyExceeded(NFT nft);
error WrongPaymentValue(uint256 nftPrice, uint256 paid);
error TransferFailed();
error FailedToPayRoyalty();
error FailedToPaySale();
error IsNotNFTOwner();
error MaxSupplyLessThanAlreadyMinted(uint8 currentSupply, uint8 maxSupply);
error InexistentNFT(uint16 idxNFT);