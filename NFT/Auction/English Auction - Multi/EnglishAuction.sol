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

contract EnglishAuction is Ownable{
    event Start(uint itemId, uint tokeId, uint time);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

   

    address payable public seller;

    // address => auction munber -> amount
    mapping(address => mapping(uint=>uint)) public bids;
    uint public bidderAmount ;

    
  error NotSeller();
  error AuctionStillRunning();  
  error NotStarted();
  error AuctionEnded();
  error BidHigher();
  error AuctionNotEnded();
  error AlreadyHighestBidder();
  error AuctionInProcess();


   constructor() {   
     seller = payable(msg.sender);
     }


}