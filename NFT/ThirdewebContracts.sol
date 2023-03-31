

  pragma solidity ^0.8.9;






      struct AllowlistProof {
          bytes32[] proof;
          uint256 quantityLimitPerWallet;
          uint256 pricePerToken;
          address currency;
      }



  abstract contract Myerc1155 is IERC1155 {
          function claim(
          address _receiver,
          uint256 _tokenId,
          uint256 _quantity,
          address _currency,
          uint256 _pricePerToken,
          AllowlistProof calldata _allowlistProof,
        bytes memory _data
      ) external virtual  ;
  }

  abstract contract Myerc20 is IERC20 {
          function claim(
          address _receiver,
          uint256 _quantity,
          address _currency,
          uint256 _pricePerToken,
          AllowlistProof calldata _allowlistProof,
        bytes memory _data
      ) external virtual  ;

      function burnFrom(address account, uint256 amount)  external virtual  ;
  }



  //color card
  // abstract contract Myerc721 is IERC721{
  //         function claim(
  //         address _receiver,
  //         uint256 _quantity,
  //         address _currency,
  //         uint256 _pricePerToken, 
  //          AllowlistProof calldata _allowlistProof,
  //         // bytes32[] proof,
  //         // uint256 quantityLimitPerWallet,
  //         // uint proof_pricePerToken,
  //         //  address proof_currency,
  //        bytes memory _data
  //     ) external virtual  ;

  //   //   function balanceOf(address who) external virtual view returns (uint256);
  //      function totalSupply() external virtual view returns (uint256);
  //     function ownerOf(uint256 tokenId) public view virtual override returns (address) ;
  // //   function tokenURI(uint256 tokenId) external virtual view returns (string memory);
  // }



  //mainnet
  // ERC 1155 - 3D sculptures - 0x3B397d021c355970c1B598749b95235cA38b44eA
  // ERC 721 - Colour Cards - 0xC2C717cAc3da3FFfc19E3F63A175Eb80A1Bd312d
  // Z1 (reward token) - 0xf693aecA9248aB930D6528EC16faB50C2b68912f
  // GZ1 (ecosystem token) - 0x3A3778E61fe9e86867Cf312c54685D1f583B8886
  // ERC 1155 (gold bar) - 0x104E5050cC962620b7a19563038472a75084F2F2


  //testnet
  // 3D collection ERC1155 (for staking collection) -0x5BC72F4c1dd70F1B3f4c858Aa1A6Ee44D7fe7187
  // Colour Card collection ERC721 - 0xA8DA6068601dFEBCbd76e679c9A18f9C224A6C49
  // Gold Bar  ERC1155 - 0xAE299C0F7B021e0aC52af76D9208Df1aB31F35F5
  // GZ1 token - 0x7B14CdAE97385a411bb6a47898254b3e28CAdEdB 



  contract myconnector is Ownable  {

          // input stake token
      Myerc20 public immutable rewardsToken; //change it to constant and addresses
      Myerc1155 public immutable goldBarCollection;
      IERC721 public immutable colourCards ;


      bytes32[] allowlist = new bytes32[](1);

      address constant dead_address = 0x000000000000000000000000000000000000dEaD ; 
      address constant _currency = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE ; //thirdwebDefault
      uint quantityLimitPerWallet_proof =  115792089237316195423570985008687907853269984665640564039457584007913129639935 ;

      uint public storageRewards = 120e18 ;
      uint public exchangeRewards = 100e18 ;
      uint public burnRewards = 10e18 ;



      constructor(Myerc1155 _goldBarCollection, IERC721 _colourCards , Myerc20  _tokenAddress)  {
        goldBarCollection = _goldBarCollection;
        rewardsToken = _tokenAddress;
        colourCards= _colourCards ;
        allowlist[0] = 0x0000000000000000000000000000000000000000000000000000000000000000; //thirdwebDefault
      }

    //the thrirdweb Proof array
      AllowlistProof  ALLOW_LIST_PROOF = AllowlistProof(allowlist, quantityLimitPerWallet_proof, 0, _currency);


  /*
  * mint erc1155 goldbar and burn the 120gz1
  */  

      function Storage(uint256 _erc1155TokenId, uint256 _erc1155TokenAmount, uint _erc1155price) public {
            require(rewardsToken.balanceOf(msg.sender)> storageRewards*_erc1155TokenAmount, "You don't own enough GZ1 tokens");
            rewardsToken.burnFrom(msg.sender, storageRewards*_erc1155TokenAmount) ;  
            goldBarCollection.claim(msg.sender, _erc1155TokenId, _erc1155TokenAmount ,_currency,_erc1155price,ALLOW_LIST_PROOF ,'0x') ; 
  }

  /*
  * burn erc1155 goldbar receive 100Gz1
  */
      function Exchange (uint _erc1155TokenId, uint _erc1155TokenAmount )  public  {
          require(goldBarCollection.balanceOf(msg.sender, _erc1155TokenId) >= _erc1155TokenAmount, 'you dont have enough balance');
          goldBarCollection.safeTransferFrom(msg.sender, dead_address, _erc1155TokenId, _erc1155TokenAmount, '0x');
          rewardsToken.claim(msg.sender, exchangeRewards*_erc1155TokenAmount ,_currency,0,ALLOW_LIST_PROOF ,'0x') ; // Mint the REWARD token
      }

      /*
  * burn colourCards- ERC721 receive 10Gz1
  */
      function Burn (uint[] memory id )  public  {
          require(id.length >0, "No tokenId inserted");
          for (uint i=0 ; i< id.length; i++){
                require(colourCards.ownerOf(id[i])== msg.sender,"You don't own this token");
                colourCards.safeTransferFrom(msg.sender, dead_address, id[i]);           
          }
            rewardsToken.claim(msg.sender, burnRewards*id.length ,_currency,0,ALLOW_LIST_PROOF ,'0x') ; 
    
      }


      /*onlyOwner function*/

      function setStorageRewards (uint _newReward) public onlyOwner  {
      storageRewards = _newReward ;   
      }

      function setExchangeRewards (uint _newReward) public onlyOwner  {
      exchangeRewards = _newReward ;   
      }

      function setBurnRewards (uint _newReward) public onlyOwner  {
      burnRewards = _newReward ;   
      }


    // function walletOfOwnerColors(address _owner)
    //   public
    //   view
    //   returns (uint256[] memory)
    // {
    //   uint256 ownerTokenCount = colourCards.balanceOf(_owner);

    //   uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    //   uint256 tokenIndex = 0;

    //   for (uint256 i = 0; i < colourCards.totalSupply(); i++) {
    //     if (_owner == colourCards.ownerOf(i)) {
    //       tokenIds[tokenIndex] = i;
    //       tokenIndex++;
    //     }
    //   }

    //   return tokenIds;
    // }



  }
