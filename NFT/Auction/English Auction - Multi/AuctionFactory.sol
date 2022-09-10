// SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";
import './EnglishAuction.sol';

   contract AuctionFactory is EnglishAuction     {
        using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _soldCounter;


        enum State {
        Declared,
        Started,
        Running,
        Ended,
        Canceled
    }

    struct Auctions {
        uint token ;
        uint startingBid;
        uint highestBid ;
        address highestBidder ;
        uint startTime; 
        uint endTime;
        State auctionState;
    }

    IERC721 immutable nftCollection ;

    mapping (uint => Auctions) private auction ;


    // event AuctionCreated(address auctionContract, address owner, uint numAuctions, address[] allAuctions);

     constructor(  IERC721 _nftCollection ) {
        nftCollection = _nftCollection ;
        }





    function createAuction(uint _tokenId, uint _startingBid, uint _startTime, uint _endTime) external onlyOwner {
          _tokenIdCounter.increment();
           uint256 tokenId = _tokenIdCounter.current();
         
   auction[tokenId] = Auctions(
          _tokenId,
          _startingBid,
          _startingBid, //_startingBid = highestBid
          msg.sender,
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
        // auction[itemId].endTime = uint32(block.timestamp) + auctionTime;
        emit Start(itemId , tokenId , block.timestamp );
    }


    /**
     * @dev customers to bid
     * bid if not already higher bidder
     */

    function AuctionBid(uint itemId) public payable  {
        if(auction[itemId].auctionState != State.Running) revert(); 
          uint end = auction[itemId].endTime ;
          address highestBidder = auction[itemId].highestBidder ;
          uint highestBid = auction[itemId].highestBid ;
        if (now() > end) revert AuctionEnded();
        if(msg.sender== highestBidder) revert AlreadyHighestBidder();
        if(msg.value <= highestBid) revert BidHigher();

        if (highestBidder != address(0)) {
            bids[highestBidder][itemId] += highestBid;
        }

        auction[itemId].highestBidder = msg.sender;
        auction[itemId].highestBid  = msg.value;
        bidderAmount+=1 ;

        emit Bid(msg.sender, msg.value);
    }



    
       function AuctionEnd(uint itemId) external onlyOwner {
           
        uint end = auction[itemId].endTime ;
        uint tokenId = auction[itemId].token ;
        address highestBidder = auction[itemId].highestBidder ;
        uint highestBid = auction[itemId].highestBid ;
        if (now() < end) revert AuctionNotEnded();
        if( auction[itemId].auctionState != State.Running ) revert AuctionEnded();


        auction[itemId].auctionState = State.Ended ;

        if (highestBidder != owner()) {
            nftCollection.safeTransferFrom(address(this), highestBidder, tokenId);
            seller.transfer(highestBid);
             _soldCounter.increment();
        }
         else {
            nftCollection.safeTransferFrom(address(this), seller, tokenId);
              _soldCounter.increment();
        }

        emit End(highestBidder, highestBid);
    }

 
    function AuctionCanceled(uint itemId) external onlyOwner{
        if ( auction[itemId].auctionState == State.Declared &&  auction[itemId].startTime < block.timestamp ) revert();
       uint tokenId = auction[itemId].token ;
        auction[itemId].highestBidder = address(0) ;
        auction[itemId].startTime = 0 ;
        auction[itemId].endTime = 0 ;

       auction[itemId].auctionState = State.Canceled ;
       nftCollection.safeTransferFrom(address(this), msg.sender, tokenId);
       _tokenIdCounter.decrement();

    }


    /**
     * @dev customers can withdraw the lasts bids unless you are the highest bidder 
     */

    function withdraw(uint itemId) external {
        uint bal = bids[msg.sender][itemId];
        bids[msg.sender][itemId] = 0;
        bidderAmount-=1 ;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }


 /**
     * @dev view funtions. total opened, 
     */


  /* Returns all sold market items */
    function getSoldNfts() public view returns (Auctions[] memory) {
   // uint itemCount = _tokenIdCounter.current();
    uint soldItemCount = _soldCounter.current();
    uint currentIndex = 0;

    Auctions[] memory items = new Auctions[](soldItemCount);
    for (uint i = 0; i <= soldItemCount; i++) {
        if (auction[i+1].auctionState == State.Ended) {
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
    //uint unsoldItemCountitemCount = _tokenIdCounter.current() -  _soldCounter.current();
    uint currentIndex = 0;

    Auctions[] memory items = new Auctions[](itemCount);
    for (uint i = 0; i <= itemCount; i++) {
        if (auction[i+1].highestBidder == owner()) {
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