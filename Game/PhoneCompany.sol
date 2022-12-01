// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

     
     //room open, close, full

    //fees for participating the game
     uint public fees =0.05 ether ;


    enum Status {
        Open,
        Full,
        Close
    }

    // game data tracking
    struct Game {
        uint room;
        address player1;
        address player2;
        uint tokenId1 ;
        uint  tokenId2;
        bool roomPayable ;
        Status roomStatus ;
        address payable winner;
    }

    IERC721 nftContract ;

    mapping(uint256 => Game) public gamePlay;

    // // map game to balances
    // mapping(address => mapping(uint256 => Game)) public balances;
    // // set-up event for emitting once character minted to read out values
    // event NewGame(uint256 id, address indexed player);

    // // only admin account can unlock escrow


    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
      constructor(address _nftContract) {
        nftContract = IERC721(_nftContract);
    }


    // staking eth +nft
    // 1 function payable other 1 will be for free game
    //for 1st player 2nd player is joining via joining function
    function createGamePayable (
        uint _tokenId1 
    ) payable external {
        require(msg.value>=fees, 'Not enough fees');

        _roomIds.increment();
        uint256 itemId = _roomIds.current();

        nftContract.transferFrom(msg.sender, address(this), _tokenId1) ;

        bool roomPayable= true;
        if (fees==0)
        roomPayable = false;


        gamePlay[itemId] = Game(
            itemId,
            msg.sender,
             address(0),
            _tokenId1,
             0,
            roomPayable,
            Status.Open,
            payable(address(0))

        );    

        emit RoomCreated(itemId,  msg.sender,  true);
    }

//second player is joining opened Game
    function joinGamePayable (uint roomId, uint  _tokenId2)   public  payable  {
     require(gamePlay[roomId].roomStatus == Status.Open, 'Game not open' );
     require(msg.sender !=  gamePlay[roomId].player1, 'Cant play against yourself');

     if (gamePlay[roomId].roomPayable ==true)
     require(msg.value>=fees, 'Not enough fees');

     nftContract.transferFrom(msg.sender, address(this), _tokenId2) ;

    gamePlay[roomId].player2 = msg.sender ;
    gamePlay[roomId].roomStatus == Status.Full ;

    emit RoomJoined(roomId,  msg.sender,  true);

    }

   //set Winner from dapp
    function setWinnerLooser (uint roomId, address winner) public  onlyOwner {
        gamePlay[roomId].winner = payable(winner) ;
    }

    function Withdraw(uint roomId) public payable  {
        //require not free game
        require(msg.sender == gamePlay[roomId].player1 || msg.sender == gamePlay[roomId].player2, 'Not played for room');
        require(gamePlay[roomId].roomStatus == Status.Full ,  'Not right game' );

   
        address winner = gamePlay[roomId].winner ;
        if (msg.sender == gamePlay[roomId].player1){
            gamePlay[roomId].player1 = address(0);
            nftContract.safeTransferFrom(address(this),msg.sender ,   gamePlay[roomId].tokenId1) ;
                 
        }else {
            gamePlay[roomId].player2 = address(0);
            nftContract.safeTransferFrom(address(this),msg.sender ,   gamePlay[roomId].tokenId2) ;
             
        }
        if (msg.sender == winner && gamePlay[roomId].roomPayable ==true) {
          payable(owner()).transfer(fees);
          //transfer to winner
          payable(winner).transfer(msg.value);        }


        if (gamePlay[roomId].player1 ==  address(0) && gamePlay[roomId].player2 ==  address(0))
        gamePlay[roomId].roomStatus == Status.Close ;
   
    
    
    }


    function changeFees (uint _newFees) public onlyOwner {
      fees = _newFees;
    }
  

    //retrieve openRoom


         /*retrieve nft address, and nft number emitted by user */
    function getFreeRoom() public view returns(uint256[] memory){ 
        uint itemCount = _roomIds.current();
        // uint itemReturned = _tokenIds.current() -  _releasedIds.current();
        // IERC721[] memory Nftaddress = new IERC721[](itemReturned);
        uint[] memory freeRoom = new uint[](itemCount);

          uint currentIndex = 0;

      //  FractionWrap[] memory items = new FractionWrap[](itemReturned);
        for (uint i = 0; i <= itemCount; i++) {
              if (gamePlay[i+1].roomStatus == Status.Open ) {
            uint currentId = i + 1;
             Game storage currentItem = gamePlay[currentId];
             freeRoom[currentIndex] = currentItem.room ;
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

}