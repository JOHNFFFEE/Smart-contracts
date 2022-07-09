// SPDX-License-Identifier: MIT
// Edited by LAx
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract FractionalizedNFT is ERC20, Ownable, ERC20Permit, ERC721Holder {
    IERC721 immutable public Nft;
    uint256 public tokenId;
    uint256 immutable public salePrice ;
    uint public ERC20_tokenAmount ;

    event Fractionalized(
        address indexed onwer,
        uint tokenId,
        uint256 amount
    );

    event NftPurchased(
        address indexed onwer,
        uint price,
        uint256 timstamp
    );

    event TokensPurchased(
        address indexed onwer,
        uint price,
        uint256 timstamp
    );

    event ERC20Redeemed(
        address indexed onwer,
        uint amount,
        uint256 price
    );

    event BoughtBack(
        address indexed onwer,
        uint time
    );

  error NotEnoughEther();
  error NotNftOwner();
  error NotAllERC20Token();
  error InvalidMintAmount();
  error MaxSupply();
  error NotEnoughToRedeem();



    constructor( address _ERC721, string memory _name , string memory _symbol, uint _price ) ERC20(_name, _symbol) ERC20Permit(_name) {
        Nft = IERC721(_ERC721);
        salePrice = _price ;
    }

  /**
     * @dev Fractionalize the Nft into multiple ERC20 Tokens.
     * _amount of tokens to be divised 
     * approve nft before transfer
     */

    function Fractionalize(uint _tokenId , uint _amount) external   {
        if (Nft.ownerOf(_tokenId) != msg.sender) revert NotNftOwner() ;
        Nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        tokenId = _tokenId;
        ERC20_tokenAmount = _amount ;
        // _mint(address(this), ERC20_tokenAmount);

        emit Fractionalized(msg.sender , tokenId , ERC20_tokenAmount);
    }

  /**
     * @dev PurchaseNft with all the required money
     * conflict, since a user can buy nft and the erc20 will be worthless  -- optional can be removed
     */
    function purchaseNft() external payable {
        if (msg.value < salePrice)  revert NotEnoughEther() ;
        Nft.transferFrom(address(this), msg.sender, tokenId);

        emit NftPurchased(msg.sender, msg.value,  block.timestamp);
    }


      modifier purchaseCompliance(uint256 _amount) {
    if (_amount <= 0) revert InvalidMintAmount();
    _;
  }

        modifier Compliance(uint256 _amount) {
    if (totalSupply() + _amount > ERC20_tokenAmount) revert MaxSupply();
    _;
  }


  /**
     * @dev TokensPurchase to sell the fractionized tokens
     */

    function TokensPurchase( uint _amount) external  purchaseCompliance(_amount) Compliance(_amount)  payable  {
        uint tokenPrice = _amount *  (salePrice/ERC20_tokenAmount) ;
        if (msg.value < tokenPrice)  revert NotEnoughEther() ;
        // transferFrom(address(this), msg.sender, _amount);
         _mint(msg.sender, _amount);

        emit TokensPurchased(msg.sender, msg.value,  block.timestamp);
    }

  /**
     * @dev Clients to redeem some amount of the ERC20tokens
     * To redeem its needed to have sell some tokens
     */

    function redeem(uint256 _amount) external  purchaseCompliance(_amount) {
       if (balanceOf(msg.sender) < _amount) revert NotEnoughToRedeem() ;   //redundant

        uint256 totalEther = address(this).balance;
        uint256 toRedeem = _amount * totalEther / ERC20_tokenAmount;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(toRedeem);

        emit ERC20Redeemed(msg.sender, _amount, toRedeem );
    }

  /**
     * @dev Exchange all ERC20tokens for NFT.
     * approve erc20 for burning tokens
     */
    function BuyBack() external {
        if (balanceOf(msg.sender) != ERC20_tokenAmount) revert NotAllERC20Token() ;
          _burn(msg.sender, ERC20_tokenAmount);
          Nft.safeTransferFrom(address(this),msg.sender , tokenId);
      
       emit BoughtBack(msg.sender, block.timestamp);
    }


    
  function withdraw() public onlyOwner  {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }


}