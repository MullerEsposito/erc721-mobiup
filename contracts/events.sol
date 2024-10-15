//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

event NFTMinted(uint16 nftType, uint32 tokenId, address from, address to);
event NFTTransfered(uint32 tokenId, address from, address to);
event NFTCreated(uint16 numberOfNFTs, string _baseURI);
event NFTUpdated(uint16 nftType);