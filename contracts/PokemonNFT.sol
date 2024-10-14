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
    mapping (uint32 => TokenData) private _mapTokenIdTokenData;
    mapping (uint32 => uint8) private _mapTokenIdPositionInType;

    string public contractURI;
    uint256 public royaltyFee;
    uint32 public nextTokenId = 1;
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
            typeNFT: numberOfNFTs,
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
            typeNFT: foundNFT.typeNFT,
            currentSupply: foundNFT.currentSupply,
            maxSupply: _maxSupply,
            mintPrice: _mintPrice,
            baseURI: _baseURI
        });

        emit NFCUpdated(_typeNFT);
    }

    function mintNFT(MintParams memory _mintParams) public payable{
        NFT storage nft = nfts[_mintParams.typeNFT];
        _mintValidations(nft);

        uint32 tokenId = nextTokenId++;
        string memory tokenURI = _generateTokenURI(tokenId);        

        _mapTokenIdTokenData[tokenId].nftType = nft.typeNFT;
        _mapTokenIdPositionInType[tokenId] = ++nft.currentSupply;

        if (_mintParams.to == address(0)) {
            _safeMint(msg.sender, tokenId);
            _mapTokenIdTokenData[tokenId].royaltyAddress = msg.sender;
            emit NFTMinted(nft.typeNFT, tokenId, msg.sender, msg.sender);
        } else {
            _safeMint(_mintParams.to, tokenId);
            _mapTokenIdTokenData[tokenId].royaltyAddress = _mintParams.to;
            emit NFTMinted(nft.typeNFT, tokenId, msg.sender, _mintParams.to);
        }
        _setTokenURI(tokenId, tokenURI);        
    }

    function _mintValidations(NFT memory _nft) internal {
        if (_nft.typeNFT > numberOfNFTs || _nft.typeNFT == 0) revert InexistentNFT(_nft.typeNFT);        
        if (_nft.maxSupply == 0) revert SupplyUnavailable();
        if (_nft.currentSupply >= _nft.maxSupply) revert SupplyExceeded(_nft);
        if (msg.value != _nft.mintPrice) revert WrongPaymentValue(_nft.mintPrice, msg.value);
    }

    function _generateTokenURI(uint32 _tokenId) internal view returns (string memory) {
        TokenData storage tokenData = _mapTokenIdTokenData[_tokenId];
        NFT storage nft = nfts[tokenData.nftType];
        uint8 tokenNumber = _mapTokenIdPositionInType[_tokenId];

        return string(abi.encodePacked(nft.baseURI, Strings.toString(tokenNumber), ".json"));
    }

    function updateTokenURI(uint32 _tokenId, string calldata _newTokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _newTokenURI);
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