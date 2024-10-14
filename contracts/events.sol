//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

event NFTMinted(uint16 typeNFT, uint32 idToken, address from, address to);
event NFTTransfered(uint32 idToken, address from, address to);
event NFCCreated(uint16 numberOfNFTs, string _baseURI);
event NFCUpdated(uint16 typeNFT);