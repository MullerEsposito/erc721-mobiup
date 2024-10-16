//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct NFT {
    uint16 typeNFT;
    uint8 currentSupply;
    uint8 maxSupply;
    uint256 mintPrice;
    string baseURI;
}