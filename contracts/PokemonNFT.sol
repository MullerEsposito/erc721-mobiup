// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./structs/NFT.sol";
import "./errors.sol";
import "./events.sol";

contract PokemonNFT is ERC721URIStorage, Ownable {
    mapping (uint => NFT) nfts;
    mapping (uint8 => uint8) private _mapTokenIdNFTType;
    mapping (uint8 => uint8) private _mapTokenIdPositionInType;
    mapping (uint8 => address) private _mapTokenIdNFTOwner;

    address public royaltyRecipient;
    string public contractURI;
    uint256 public royaltyFee;
    uint8 public nextTokenId;
    
    uint8 public constant SUPPLY = 100;

    constructor(string memory _contractURI, address _royaltyRecipient, uint256 _royaltyFee, string memory _name, string memory _symbol) 
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        contractURI = _contractURI;
        royaltyRecipient = _royaltyRecipient;
        royaltyFee = _royaltyFee;

        createNFCs();
    }

    function mintNFTTo(address to, uint8 idxNFT) public payable {
        NFT storage nft = nfts[idxNFT];
        uint8 tokenId = nextTokenId++;
        
        if (nft.maxSupply == 0) revert SupplyUnavailable();
        if (nft.currentSupply >= nft.maxSupply) revert SupplyExceeded(idxNFT);
        if (msg.value != nft.mintPrice) revert WrongPaymentValue(nft.mintPrice, msg.value);
        
        nft.currentSupply += 1;
        _safeMint(to, idxNFT);
        _mapTokenIdNFTType[tokenId] = idxNFT;
        _mapTokenIdPositionInType[tokenId] = nft.currentSupply;
        _mapTokenIdNFTOwner[tokenId] = msg.sender;
        
        emit NFTMinted(idxNFT, tokenId, msg.sender);
    }

    function mintNFT(uint8 idxNFT) public payable{
        NFT storage nft = nfts[idxNFT];
        uint8 tokenId = nextTokenId++;
        
        if (nft.maxSupply == 0) revert SupplyUnavailable();
        if (nft.currentSupply >= nft.maxSupply) revert SupplyExceeded(idxNFT);
        if (msg.value != nft.mintPrice) revert WrongPaymentValue(nft.mintPrice, msg.value);
        
        nft.currentSupply += 1;
        _safeMint(msg.sender, idxNFT);
        _mapTokenIdNFTType[tokenId] = idxNFT;
        _mapTokenIdPositionInType[tokenId] = nft.currentSupply;
        _mapTokenIdNFTOwner[tokenId] = msg.sender;
        
        emit NFTMinted(idxNFT, tokenId, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint8 idxNFT = _mapTokenIdNFTType[uint8(tokenId)];
        NFT storage nft = nfts[idxNFT];
        uint8 tokenNumber = _mapTokenIdPositionInType[uint8(tokenId)];

        return string(abi.encodePacked(nft.baseURI, Strings.toString(tokenNumber), ".json"));
    }

    function transferNFT(address to, uint8 tokenId) public payable {
        uint256 salePrice = msg.value;
        uint256 royaltyValue = salePrice * (royaltyFee / 100);

        if (msg.sender != _mapTokenIdNFTOwner[tokenId]) revert IsNotNFTOwner();

        (bool success, ) = payable(owner()).call{value: royaltyValue}("");
        if (!success) revert FailedToPayRoyalty();

        _transfer(msg.sender, to, tokenId);

        (success, ) = msg.sender.call{value: salePrice - royaltyValue}("");
        if (!success) revert FailedToPaySale();

        _mapTokenIdNFTOwner[tokenId] = to;

        emit NFTTransfered(tokenId, msg.sender, to);
    }

    function setContractURI(string memory _contractURI) public {
        contractURI = _contractURI;
    }

    function withDraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }

    function createNFCs() internal {
        nfts[1] = NFT({
            currentSupply: 0,
            maxSupply: 10,
            mintPrice: 0.01 ether,
            baseURI: "https://coral-able-tarantula-122.mypinata.cloud/ipfs/QmWqyciVSoroPvWtT7XvRtVJYzPrgSYTf5eMbtFZYg8VM9/"
        });
        nfts[2] = NFT({
            currentSupply: 0,
            maxSupply: 5,
            mintPrice: 0.01 ether,
            baseURI: "https://coral-able-tarantula-122.mypinata.cloud/ipfs/QmWqyciVSoroPvWtT7XvRtVJYzPrgSYTf5eMbtFZYg8VM9/"
        });
        nfts[3] = NFT({
            currentSupply: 0,
            maxSupply: 3,
            mintPrice: 0.01 ether,
            baseURI: "https://coral-able-tarantula-122.mypinata.cloud/ipfs/QmWqyciVSoroPvWtT7XvRtVJYzPrgSYTf5eMbtFZYg8VM9/"
        });
    }   
}