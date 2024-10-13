//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

event NFTMinted(uint8 idxNFT, uint8 idToken, address to);
event NFTMintedTo(uint8 idxNFT, uint8 idToken, address from, address to);
event NFTTransfered(uint8 idToken, address from, address to);
event NFCCreated(uint16 numberOfNFTs, string _baseURI);
event NFCUpdated(uint16 idxNFT);