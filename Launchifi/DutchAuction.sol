// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract AuctionFactory is Ownable{
    event Start(uint itemId, uint tokeId, uint time);
    event Bid(address indexed sender, uint amount);
    event Cancelled( uint tokenId);
    //event End(address winner, uint amount);

   

    address payable public seller;

  error AuctionEnded();
  error AuctionInProcess();


   constructor() {   
     seller = payable(msg.sender);
     }


}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Counters.sol";


   contract DutchFactory is AuctionFactory     {
        using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _soldCounter;


        enum State {
        Declared,
        Started,
        Running,
        Ended,
        Sold,
        Canceled
    }


    struct Auctions {
        //tokenId
        uint token ;
        //starting price bid
        uint startingPrice;
        //how many to reduce ecery x times
        uint discountRate ;
        uint startTime; 
        uint endTime;
        State auctionState;
    }
   //nft collection
    IERC721 immutable nftCollection ;

    //time to decrement the price , in second
    uint immutable timeToCalculate;

    mapping (uint => Auctions) private auction ;


    // event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

     constructor(  IERC721 _nftCollection , uint _timeToCalculate) {
        nftCollection = _nftCollection ;
        timeToCalculate= _timeToCalculate;
      //   seller = payable(msg.sender);
        }



    function createAuction(uint _tokenId, uint _startingPrice, uint _discountRate,  uint _startTime, uint _endTime) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        
        auction[tokenId] = Auctions(
                _tokenId,
                _startingPrice,
                _discountRate,
                _startTime,
                _endTime,
                State.Declared
                );  
    }
    
    
  /**
     * @dev to start the auction
     * can't start if not contract owner neither the auction has not ended
        started = true;
     */
    function AuctionStart(uint itemId) external onlyOwner {
        if (auction[itemId].auctionState != State.Declared) revert AuctionInProcess();
        uint tokenId = auction[itemId].token ;
        nftCollection.transferFrom(msg.sender, address(this), tokenId);
        auction[itemId].auctionState = State.Running ;

        emit Start(itemId , tokenId , block.timestamp );
    }


    /**
     * @dev customers to buy
     */

    function AuctionBuy(uint itemId) public payable  {
        if(auction[itemId].auctionState != State.Running) revert(); 
          uint end = auction[itemId].endTime ;
        if (now() > end) revert AuctionEnded();
         
        uint price = getPrice(itemId);
        require(msg.value >= price, "ETH < price");

        nftCollection.transferFrom(address(this), msg.sender, auction[itemId].token);
        seller.transfer(price);
        _soldCounter.increment();
        auction[itemId].auctionState = State.Sold ;
        emit Bid(msg.sender, msg.value);
    }


 
     /**
     * @dev cancel auction
     */
    function AuctionCanceled(uint itemId) external onlyOwner{
        if (auction[itemId].startTime < block.timestamp && auction[itemId].endTime > block.timestamp ) revert AuctionInProcess();
        uint tokenId = auction[itemId].token ;
        auction[itemId].startTime = 0 ;
        auction[itemId].endTime = 0 ;

        auction[itemId].auctionState = State.Canceled ;
        nftCollection.safeTransferFrom(address(this), msg.sender, tokenId);
        _tokenIdCounter.decrement();

         emit Cancelled (tokenId);
    }


      /**
     * @dev calculate price auction
     */   
    function getPrice(uint itemId) public view returns (uint256) {
        if (auction[itemId].auctionState == State.Canceled ||  auction[itemId].auctionState == State.Sold)
        return  0 ;

        uint256 minutesElapsed = (block.timestamp - auction[itemId].startTime) / timeToCalculate;
        return auction[itemId].startingPrice - (minutesElapsed * auction[itemId].discountRate);
    }

/*set new discount rate to auctionID*/
    function setDiscountRate (uint itemId ,uint256 _discountRate) public onlyOwner {
        auction[itemId].discountRate = _discountRate;
    }


  /* Returns all sold market items */
    function getSoldNfts() public view returns (Auctions[] memory) {
        uint soldItemCount = _soldCounter.current();
        uint currentIndex = 0;

        Auctions[] memory items = new Auctions[](soldItemCount);
        for (uint i = 0; i <= soldItemCount; i++) {
            if (auction[i+1].auctionState == State.Sold) {
                uint currentId = i + 1;
                Auctions storage currentItem = auction[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

    return items;
    }



  /* Returns all sold market items */
    function getOpenNfts() public view returns (Auctions[] memory) {
        uint itemCount = _tokenIdCounter.current();
        uint unsoldItemCountitemCount = _tokenIdCounter.current() -  _soldCounter.current();
        uint currentIndex = 0;

        Auctions[] memory items = new Auctions[](unsoldItemCountitemCount);
        for (uint i = 0; i <= itemCount; i++) {
            if (auction[i+1].auctionState == State.Running) {
                uint currentId = i + 1;
                Auctions storage currentItem = auction[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

    return items;
    }


    function now() view public returns (uint time){
        return  block.timestamp;
    }




}