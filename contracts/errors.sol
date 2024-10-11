//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error SupplyUnavailable();
error SupplyExceeded(uint8 idxNFT);
error WrongPaymentValue(uint256 nftPrice, uint256 paid);
error TransferFailed();
error FailedToPayRoyalty();
error FailedToPaySale();
error IsNotNFTOwner();