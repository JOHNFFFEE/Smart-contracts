// SPDX-License-Identifier: MIT
//adapted by LAx

/*
*ERC1155 contract, for random mint 4 types of robots
* gifting funcition for unity 
* gifting function for multiples addresses with a random mint.
* limit of mint per trx
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";


contract Irobots is ERC1155, Ownable, ERC1155Supply {
    
  string public name;
  string public symbol;

  uint256 public walletMintAmount = 3;
  // uint256 public trxMintAmount = 3;

  mapping(uint => string) public tokenURI;
  mapping(address =>uint ) private NftPerWallet;

  string  public mytokenURI= "ipfs://QmQpe1vqn8CB4ujEjscWJP7qpGTpg8EHaj37EcPTXepfG2/" ;

    uint256 private constant Robot1 = 1;
    uint256 private constant Robot2 = 2;
    uint256 private constant Robot3 = 3;
    uint256 private constant Robot4 = 4;

  constructor() ERC1155("")  {
    name = "WLadi";
    symbol = "WLadi";
  }


  modifier mintCompliance(uint256 amount) {
    require(amount +  NftPerWallet[msg.sender] <= walletMintAmount, "Max trx per wallet exceeded!");
    _;
  }

   function mint(uint256 amount)  mintCompliance(amount)
        public{    
      for (uint256 i ; i<amount ; i++){
        uint tokenId = setMyRandom(i**5)  ;   
        _mint(msg.sender, tokenId, 1, ''); 
        NftPerWallet[msg.sender] +=1 ;

      }     
  } 


//gift 1 nft to address
  function giftedMint(uint256 tokenId , address _receiver) public onlyOwner {
   _mint(_receiver, tokenId, 1,'');
   NftPerWallet[_receiver] +=1 ;
  } 


  function giftedMintBatch(address[] memory _receiver) public onlyOwner {
      for (uint256 i = 0; i < _receiver.length; i++) {
      uint tokenId = setMyRandom(i**2)  ;   
   _mint(_receiver[i], tokenId, 1,'');
   NftPerWallet[_receiver[i]] +=1 ;
      }
  }


  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }

   function setURI(string memory newuri) public onlyOwner {
        mytokenURI = newuri;
    }

//for random id based 
  function setRandom(uint seed) internal view returns (uint256) {
      uint256 random = uint256(keccak256(
        abi.encodePacked(
        msg.sender,
        block.coinbase,
        block.difficulty,
        block.gaslimit,
        block.timestamp,
        tx.gasprice,        
        block.number,
        seed
          )
        )) % 100; 
        random+=1;
        return random ;
  }


  function setMyRandom(uint seed) internal view returns (uint256) {
      uint256 random = setRandom(seed);
      if (random <25){
        return 1 ; 
      }
     else if (random>25 && random <50){
     return 2;
     }    
     else if (random>50 && random <75){
     return 3;
      }
      else return 4 ;
  }

      function uri(uint256 _tokenid) public override view returns  (string memory) {
        return string(
            abi.encodePacked(
               mytokenURI,
                Strings.toString(_tokenid),".json"
            )
        );
    }


        function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function balanceAll() public view  returns(uint256){
      return totalSupply(1)+totalSupply(2)+totalSupply(3)+totalSupply(4);
    }


//in case
    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
  }


}