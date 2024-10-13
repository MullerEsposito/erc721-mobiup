// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./structs/NFT.sol";
import "./errors.sol";
import "./events.sol";

contract PokemonNFT is ERC721URIStorage, Ownable {
    mapping (uint16 => NFT) public nfts;
    mapping (uint8 => uint8) private _mapTokenIdNFTType;
    mapping (uint8 => uint8) private _mapTokenIdPositionInType;

    address public royaltyRecipient;
    string public contractURI;
    uint256 public royaltyFee;
    uint8 public nextTokenId = 1;
    uint16 public numberOfNFTs = 0;

    constructor(string memory _contractURI, address _royaltyRecipient, uint256 _royaltyFee, string memory _name, string memory _symbol) 
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        contractURI = _contractURI;
        royaltyRecipient = _royaltyRecipient;
        royaltyFee = _royaltyFee;
    }

    function _mintVerifications(uint8 _typeNFT) internal returns (uint8) {
        if (_typeNFT > numberOfNFTs || _typeNFT == 0) revert InexistentNFT(_typeNFT);

        NFT storage nft = nfts[_typeNFT];
        
        if (nft.maxSupply == 0) revert SupplyUnavailable();
        if (nft.currentSupply >= nft.maxSupply) revert SupplyExceeded(nft);
        if (msg.value != nft.mintPrice) revert WrongPaymentValue(nft.mintPrice, msg.value);
        
        uint8 tokenId = nextTokenId++;
        nft.currentSupply += 1;
        _mapTokenIdNFTType[tokenId] = _typeNFT;
        _mapTokenIdPositionInType[tokenId] = nft.currentSupply;

        return tokenId;
    }

    function mintNFT(uint8 _typeNFT) public payable{
        uint8 tokenId = _mintVerifications(_typeNFT);

        _safeMint(msg.sender, tokenId);
        
        emit NFTMinted(_typeNFT, tokenId, msg.sender);
    }

    function mintNFTTo(address _to, uint8 _typeNFT) public payable {
        uint8 tokenId = _mintVerifications(_typeNFT);        
        
        _safeMint(_to, tokenId);
        
        emit NFTMintedTo(_typeNFT, tokenId, msg.sender, _to);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint8 typeNFT = _mapTokenIdNFTType[uint8(tokenId)];
        NFT storage nft = nfts[typeNFT];
        uint8 tokenNumber = _mapTokenIdPositionInType[uint8(tokenId)];

        return string(abi.encodePacked(nft.baseURI, Strings.toString(tokenNumber), ".json"));
    }

    function sellNFT(address to, uint8 tokenId) public payable {
        uint256 salePrice = msg.value;
        uint256 royaltyValue = (salePrice * royaltyFee) / 100;

        if (msg.sender != ownerOf(tokenId)) revert IsNotNFTOwner();

        bool success = payable(royaltyRecipient).send(royaltyValue);
        if (!success) revert FailedToPayRoyalty();

        success = payable(msg.sender).send(salePrice - royaltyValue);
        if (!success) revert FailedToPaySale();

        _transfer(msg.sender, to, tokenId);

        emit NFTTransfered(tokenId, msg.sender, to);
    }

    function updateContractURI(string memory _contractURI) public {
        contractURI = _contractURI;
    }

    function withDraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function createNFT(uint8 _maxSupply, uint256 _mintPrice, string calldata _baseURI) public onlyOwner {
        nfts[++numberOfNFTs] = NFT({
            currentSupply: 0,
            maxSupply: _maxSupply,
            mintPrice: _mintPrice,
            baseURI: _baseURI
        });

        emit NFCCreated(numberOfNFTs, _baseURI);
    }

    function updateNFT(uint16 _typeNFT, uint8 _maxSupply, uint256 _mintPrice, string calldata _baseURI) public onlyOwner {
        NFT storage foundNFT = nfts[_typeNFT];
        if (_maxSupply < foundNFT.currentSupply) revert MaxSupplyLessThanAlreadyMinted(foundNFT.currentSupply, _maxSupply);

        nfts[_typeNFT] = NFT({
            currentSupply: foundNFT.currentSupply,
            maxSupply: _maxSupply,
            mintPrice: _mintPrice,
            baseURI: _baseURI
        });

        emit NFCUpdated(_typeNFT);
    }
}