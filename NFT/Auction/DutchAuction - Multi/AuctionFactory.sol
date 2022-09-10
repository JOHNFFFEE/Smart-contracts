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