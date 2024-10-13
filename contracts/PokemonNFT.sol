// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./structs/NFT.sol";
import "./structs/MintParams.sol";
import "./structs/TokenData.sol";
import "./errors.sol";
import "./events.sol";

contract PokemonNFT is ERC721URIStorage, Ownable {
    mapping (uint16 => NFT) public nfts;
    mapping (uint8 => TokenData) private _mapTokenIdTokenData;
    mapping (uint8 => uint8) private _mapTokenIdPositionInType;

    string public contractURI;
    uint256 public royaltyFee;
    uint8 public nextTokenId = 1;
    uint16 public numberOfNFTs = 0;

    constructor(string memory _contractURI, uint256 _royaltyFee, string memory _name, string memory _symbol) 
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        contractURI = _contractURI;
        royaltyFee = _royaltyFee;
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

    function mintNFT(MintParams memory _mintParams) public payable{
        uint8 tokenId = _mintVerifications(_mintParams.typeNFT);
        string memory tokenURI = _generateTokenURI(tokenId);

        if (_mintParams.to == address(0)) {
            _safeMint(msg.sender, tokenId);
            _mapTokenIdTokenData[tokenId].royaltyAddress = msg.sender;

        } else {
            _safeMint(_mintParams.to, tokenId);
            _mapTokenIdTokenData[tokenId].royaltyAddress = _mintParams.to;
        }
        _setTokenURI(tokenId, tokenURI);
        
        emit NFTMinted(_mintParams.typeNFT, tokenId, msg.sender);
    }

    function _mintVerifications(uint8 _typeNFT) internal returns (uint8) {
        if (_typeNFT > numberOfNFTs || _typeNFT == 0) revert InexistentNFT(_typeNFT);

        NFT storage nft = nfts[_typeNFT];
        
        if (nft.maxSupply == 0) revert SupplyUnavailable();
        if (nft.currentSupply >= nft.maxSupply) revert SupplyExceeded(nft);
        if (msg.value != nft.mintPrice) revert WrongPaymentValue(nft.mintPrice, msg.value);
        
        uint8 tokenId = nextTokenId++;
        nft.currentSupply += 1;
        _mapTokenIdTokenData[tokenId].nftType = _typeNFT;
        _mapTokenIdPositionInType[tokenId] = nft.currentSupply;

        return tokenId;
    }

    function _generateTokenURI(uint8 _tokenId) internal view returns (string memory) {
        TokenData storage tokenData = _mapTokenIdTokenData[_tokenId];
        NFT storage nft = nfts[tokenData.nftType];
        uint8 tokenNumber = _mapTokenIdPositionInType[_tokenId];

        return string(abi.encodePacked(nft.baseURI, Strings.toString(tokenNumber), ".json"));
    }
    
    function sellNFT(address to, uint8 tokenId) public payable {
        uint256 salePrice = msg.value;
        uint256 royaltyValue = (salePrice * royaltyFee) / 100;

        if (msg.sender != ownerOf(tokenId)) revert IsNotNFTOwner();

        TokenData storage tokenData = _mapTokenIdTokenData[tokenId];
        
        bool success = payable(tokenData.royaltyAddress).send(royaltyValue);
        if (!success) revert FailedToPayRoyalty();

        success = payable(msg.sender).send(salePrice - royaltyValue);
        if (!success) revert FailedToPaySale();

        _transfer(msg.sender, to, tokenId);

        emit NFTTransfered(tokenId, msg.sender, to);
    }

    function updateContractURI(string memory _contractURI) public {
        contractURI = _contractURI;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withDraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }    
}