//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard{

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
    address payable owner;
    uint256 listingPrice=0.001 ether;

    constructor() {
        owner=payable(msg.sender);
    }

    struct Marketitem{
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => Marketitem) private idToMarketItem;

    event MarketItemCreated(    
            uint indexed itemId,
            address indexed nftContract,
            uint256 indexed tokenId,
            address seller,
            address owner,
            uint256 price,
            bool sold
    );

    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }


    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price

    )
     public payable nonReentrant{
        require(price>0,"Price should be greater than 1 wei");
        require(msg.value==listingPrice,"service charge must be equal to the listing price");

        _itemIds.increment();
        uint256 itemId=_itemIds.current();

        idToMarketItem[itemId]=Marketitem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(itemId, nftContract, tokenId,msg.sender, address(0), price,false);
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public payable nonReentrant{

        uint price= idToMarketItem[itemId].price;
        uint tokenId= idToMarketItem[itemId].tokenId;

        require(msg.value==price,"Please submit the asking price to complete the purchase");
        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this) ,msg.sender,tokenId);

        idToMarketItem[itemId].owner=payable(msg.sender);
        idToMarketItem[itemId].sold=true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
            
    }

    function  fetchMarketItems() public view returns(Marketitem[] memory){

        uint256 itemCount=_itemIds.current();
        uint256 unsoldItemCount=_itemIds.current()-_itemsSold.current();
        uint256 currentIndex=0;

        Marketitem[] memory items=new Marketitem[](unsoldItemCount);
        for(uint i=0;i<itemCount;i++){
            if(idToMarketItem[i+1].owner==address(0)){
                uint currentId=idToMarketItem[i+1].itemId;
                Marketitem storage currentItem=idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns(Marketitem[] memory){
        uint totalItemCount=_itemIds.current();
        uint itemCount=0;
        uint currentIndex=0;

        for(uint i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].owner==msg.sender){
                itemCount+=1;
            }
        }
        Marketitem[] memory items=new Marketitem[](itemCount);
        for(uint i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].owner==msg.sender){
                uint currentId=i+1;
                Marketitem storage currentItem=idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }   
    function fetchItemsCreated()public view returns(Marketitem[] memory){
        uint totalItemCount=_itemIds.current();
        uint itemCount=0;
        uint currentIndex=0;

        for (uint i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].seller==msg.sender){
                itemCount+=1;
            }
        }

        Marketitem[] memory items= new Marketitem[](itemCount);
        for(uint i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].seller==msg.sender){
                uint currentId=i+1;
                Marketitem storage currentItem=idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }

}