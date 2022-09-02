// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract NFTMraket {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

uint256 listingPrice = 0.025 ether;

 address payable owner;

  constructor() {
    owner = payable(msg.sender);
  }


enum ListingStatus {
    Active,
    Sold,
    Cancelled
}


struct MarketItem {
    uint itemId;
    ListingStatus status ;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price; 
}

  mapping(uint256 => MarketItem) private idToMarketItem;


      event MarketItemCreated(
        uint itemId ,
        ListingStatus status ,
        address nftContract,
        uint tokenId,
        address seller,
        uint price
    );


        event MarketItemCancelled(
        uint itemId ,
        address nftContract,
        uint tokenId,
        address owner
    );



        event MarketItemSold(
        uint itemId ,
        address nftContract,
        uint tokenId,
        address buyer,
        uint price
    );


  /*Marketplace fees*/
function setMarketplaceFess(uint256 _fees) public view  {
         require(msg.sender ==owner,'only owner');
         listingPrice =  _fees ;
     }


  /* Places an item for sale on the marketplace */
function listToken( address _nftContract ,uint _tokenId ,  uint _price  ) external payable nonReentrant {
    require(_price > 0, "Price must be at least 1 wei");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    idToMarketItem[itemId] =  MarketItem(
    itemId,
    ListingStatus.Active,
    _nftContract ,
    _tokenId,
    msg.sender,
    payable(address(0)),
    _price
    );

 IERC721(_nftContract).approve(address(this), _tokenId);
    
  IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

    emit MarketItemCreated(
      itemId,
      ListingStatus.Active,
      _nftContract,
      _tokenId,
      msg.sender,
      _price
    );
  }

//insert modifier ?


  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
function buyToken(uint itemId ) external payable nonReentrant  {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    address nftContract = idToMarketItem[itemId].nftContract;

    require(msg.sender != idToMarketItem[itemId].seller, "Seller can not be the buyer");
    require(idToMarketItem[itemId].status == ListingStatus.Active, "Listing is not active" );
    require(msg.value >= price, "Please submit the asking price in order to complete the purchase");
//add fee to market place below
    idToMarketItem[itemId].seller.transfer(msg.value);

    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);

     idToMarketItem[itemId].status = ListingStatus.Sold ;
    _itemsSold.increment();

    payable(owner).transfer(listingPrice);

     emit MarketItemSold(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      price
    );

}

function Cancel (uint itemId ) external nonReentrant  {
    require(msg.sender == idToMarketItem[itemId].seller, " Only Seller can  cancel listing");
    require(idToMarketItem[itemId].status == ListingStatus.Active, "Listing is not active" );
     idToMarketItem[itemId].status = ListingStatus.Cancelled ;
     IERC721(idToMarketItem[itemId].nftContract).transferFrom(address(this), msg.sender, idToMarketItem[itemId].tokenId);

    emit MarketItemCancelled(
      itemId,
      _nftContract,
      _tokenId,
      msg.sender
    );
}


  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }


  /* Returns only items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }


  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }




























}

