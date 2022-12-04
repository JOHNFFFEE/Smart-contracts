// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract P2EGame is Ownable, IERC721Receiver  {

    event RoomCreated(uint RoomId, address indexed player,  bool roomPayable);
    event RoomJoined(uint RoomId, address indexed player,  bool roomPayable);

    event MarketItemListed(uint256 id, uint256 tokenId, uint amount, uint256 askingPrice);
    event itemCancelled(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice); 
    event itemSold (uint256 id, address buyer, uint256 askingPrice);

    using Counters for Counters.Counter;
    Counters.Counter public _roomIds;
    Counters.Counter public _gameClosed;


    //fees for participating the game
     uint256 public fees = 0.05 ether ;
     // owner fee in %
     uint256 public ownerfee = 10;


    enum Status {
        Open,
        Full,
        Start,
        End,
        Close
    }

    // game data tracking
    struct Game {
        uint room;
        address player1;
        address player2;
        uint tokenId1 ;
        uint  tokenId2;
        uint256 fees ; 
        bool roomPayable ;
        Status roomStatus ;
        address payable winner;
    }

    IERC721 nftContract ;

    mapping(uint256 => Game) public gamePlay;

      constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }


    // 1 function payable other 1 will be for free game
    //for 1st player 2nd player is joining via joining function
    function createGamePayable (
        uint _tokenId1, uint256 fee 
    ) payable external {
      
        _roomIds.increment();
        uint256 itemId = _roomIds.current();
        bool roomPayable ;

        nftContract.transferFrom(msg.sender, address(this), _tokenId1) ;
       
        if (fee > 0){
            require(fee >= fees, 'Not enough fees');
            roomPayable= true;
        }else{
             roomPayable = false;
        } 

        gamePlay[itemId] = Game(
            itemId,
            msg.sender,
             address(0),
            _tokenId1,
             0,
            fee,
            roomPayable,
            Status.Open,
            payable(address(0))
        );    

        emit RoomCreated(itemId,  msg.sender,  true);
    }

//second player is joining opened Game
    function joinGamePayable (uint roomId, uint  _tokenId2)  payable external {
     require(gamePlay[roomId].roomStatus == Status.Open, 'Game not open' );
     require(msg.sender !=  gamePlay[roomId].player1, 'Cant play against yourself');

     if (gamePlay[roomId].roomPayable == true)
     require(msg.value>=gamePlay[roomId].fees, 'Not enough fees');

     nftContract.transferFrom(msg.sender, address(this), _tokenId2) ;

     gamePlay[roomId].tokenId2 = _tokenId2 ;
     gamePlay[roomId].player2 = msg.sender ;
     gamePlay[roomId].roomStatus = Status.Full ;

     emit RoomJoined(roomId,  msg.sender,  true);
    }
   
   //start Game from dapp
    function setStartGame (uint roomId) public  onlyOwner {
        gamePlay[roomId].roomStatus = Status.Start ; 
    }

        function changeownerfee (uint256 _newfee) public  onlyOwner {
        ownerfee = _newfee;
    }


   //set Winner from dapp
    function setWinnerLooser (uint roomId, address winner) public  onlyOwner {
        gamePlay[roomId].roomStatus = Status.End ;
        gamePlay[roomId].winner = payable(winner) ;
        _gameClosed.increment();
    }

// if 1 player is only registered, and want to cancel
    function cancelGame(uint roomId) public {
     require(gamePlay[roomId].roomStatus == Status.Open  ,  'Second player has already registered' );
     require(msg.sender == gamePlay[roomId].player1, 'Not player');

     gamePlay[roomId].roomStatus = Status.Close ;
     _gameClosed.increment();

     nftContract.safeTransferFrom(address(this),msg.sender ,   gamePlay[roomId].tokenId1) ;
     payable(msg.sender).transfer(gamePlay[roomId].fees);  

    }


    function Withdraw(uint roomId) public  {
        //require not free game
        require(msg.sender == gamePlay[roomId].player1 || msg.sender == gamePlay[roomId].player2, 'Not played for room');
        require(gamePlay[roomId].roomStatus == Status.End  ,  'Not right game' );
   
        address winner = gamePlay[roomId].winner ;
        if (msg.sender == gamePlay[roomId].player1){
            gamePlay[roomId].player1 = address(0);
            nftContract.safeTransferFrom(address(this),msg.sender ,   gamePlay[roomId].tokenId1) ;
                 
        }else {
            gamePlay[roomId].player2 = address(0);
            nftContract.safeTransferFrom(address(this),msg.sender ,   gamePlay[roomId].tokenId2) ;             
        }

        uint ownerFees = gamePlay[roomId].fees * ownerfee / 100 ;
        uint prize = gamePlay[roomId].fees - ownerFees;
        if (msg.sender == winner && gamePlay[roomId].roomPayable ==true) {

          payable(owner()).transfer(ownerFees);
          //transfer to winner
          payable(winner).transfer(prize);
        }

        if (gamePlay[roomId].player1 ==  address(0) && gamePlay[roomId].player2 ==  address(0)){
            gamePlay[roomId].fees = 0;
            gamePlay[roomId].roomStatus = Status.Close ;    
            // delete gamePlay[roomId] ; 
        }
       
    }


 //fees to restract for owner
    function changeFees (uint _newFees) public onlyOwner {
      fees = _newFees;
    }
  

    //retrieve openRoom
    function getFreeRoom() public view returns(uint256[] memory){ 
        uint itemCount = _roomIds.current();
        uint itemAlls = itemCount -  _gameClosed.current();
        // IERC721[] memory Nftaddress = new IERC721[](itemReturned);
        uint[] memory freeRoom = new uint[](itemAlls);

          uint currentIndex = 0;

      //  FractionWrap[] memory items = new FractionWrap[](itemReturned);
        for (uint i = 0; i <= itemAlls; i++) {
            if (gamePlay[i+1].roomStatus == Status.Open ) {
                uint currentId = i +1 ;
                Game storage currentItem = gamePlay[currentId];
                freeRoom[currentIndex] = currentItem.room ;
                currentIndex += 1;
             }
        }

          return freeRoom ;
    }


//to receive nft
            function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }


      function ownerWithdrawal() public onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

}