// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@charged-particles/peppermint/contracts/ERC721PreMint.sol";


// 1 Million Peppermint Rorschachs - Demo of ERC721PreMint
contract PeppermintRorschach is ERC721PreMint, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  /// @dev Some sales-related events
  event Purchase(address indexed newOwner, uint256 amount, uint256 lastTokenId);
  event PriceUpdate(uint256 newPrice);

  /// @dev Track number of tokens sold
  Counters.Counter internal _tokenIdCounter;

  /// @dev ERC721 Base Token URI
  string internal baseURL;

  // Individual NFT Sale Price in ETH
  uint256 public price;
  // uint256 public _maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;
  // string baseURL = "";
  string ExtensionURL = ".json";
  bool paused = false;
  bool preminted = false ;

  error ContractPaused();
  error MaxMintWalletExceeded();
  error MaxSupply();
  error InvalidMintAmount();
  error InsufficientFund();
  error NoSmartContract();
  error TokenNotExisting();


  /// @dev The Deployer of this contract is also the Owner and the Pre-Mint Receiver.

    constructor(
      uint256 _price, 
      uint256 __maxSupply, 
      string memory _initBaseURI,
      uint256 _maxMintAmountPerTx,
      uint256 _maxMintAmountPerWallet
      ) ERC721PreMint("DDDD", "SDDD", _msgSender(), __maxSupply){
        baseURL = _initBaseURI;
        price = _price;
        _maxSupply = __maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    // Since we pre-mint to "owner", allow this contract to transfer on behalf of "owner" for sales.
    _setApprovalForAll(_msgSender(), address(this), true);
      }


  /// @dev Let's Pre-Mint a Gazillion NFTs!!  (wait, 2^^256-1 equals what again?)
  //1st nft remained to owner
  function preMint() external onlyOwner {
    require(!preminted, 'Already preminted');
    preminted = true ;
    _preMint();
  }

    modifier mintCompliance(uint256 _mintAmount) {
            if (msg.sender != tx.origin) revert NoSmartContract();
            if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
            if ( currentSupply() + _mintAmount > _maxSupply) revert MaxSupply();
            if (msg.value < _mintAmount * price) revert InsufficientFund();
            if(paused) revert ContractPaused();
            if(balanceOf(msg.sender) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
            _;
        }


  /**
   * @dev mint from the Pre-Mint Receiver are a simple matter of transferring the token.
   * For this reason, we can provide a very simple "batch" transfer mechanism in order to
   * save even more gas for our users.
   */
  function mint(uint256 _mintAmount) external payable virtual nonReentrant mintCompliance(_mintAmount) returns (uint256 amountTransferred) {
    uint256[] memory tokenIds = new uint256[](_mintAmount);
    for (uint256 i = 0; i < _mintAmount; i++) {
      _tokenIdCounter.increment();
      tokenIds[i] = _tokenIdCounter.current();    }
    amountTransferred = _batchTransfer(owner(), _msgSender(), tokenIds);
    emit Purchase(_msgSender(), amountTransferred, _tokenIdCounter.current());

  }


  /// @dev Set the price for sales to maintain a consistent purchase price
  function setCostPrice(uint256 _cost) public onlyOwner{
    price = _cost; 
    emit PriceUpdate(_cost);
  }

  /// @dev return uri of token ID
  /// @param tokenId  token ID to find uri for
  ///@return value for 'tokenId uri'
  function tokenURI(uint256 tokenId)public view virtual override returns (string memory){
    require(_exists(tokenId) ,'TokenNotExisting');
      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ExtensionURL))
      : '';
        }


  /// @dev Provide a Base URI for Token Metadata (override defined in ERC721.sol)
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURL;
  }

  /// @dev extension URI like 'json'
  function setExtensionURL(string memory uri) public onlyOwner{
      ExtensionURL = uri;
  } 
  
  /// @dev set URI
  function setbaseURL(string memory uri) public onlyOwner{
      baseURL = uri;
  }


  /// @dev only owner
  /// @param perTx  new max mint per transaction
  function setMaxMintAmountPerTx(uint256 perTx) public onlyOwner{
    maxMintAmountPerTx = perTx;
  }

  /// @dev only owner
  /// @param perWallet  new max mint per wallet
  function setMaxMintAmountPerWallet(uint256 perWallet) public onlyOwner{
    maxMintAmountPerWallet = perWallet;
  }     

  /// @dev pause/unpause minting
    function pause() public onlyOwner {
      paused = !paused;
    } 

  /// @dev return currentSupply of tokens
  ///@return current supply 
    function currentSupply() public view returns (uint256){
      return _tokenIdCounter.current();
    }


  //
  // Batch Transfers
  //

  function batchTransfer(
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(_msgSender(), to, tokenIds);
  }

  function batchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds
  ) external virtual returns (uint256 amountTransferred) {
    amountTransferred = _batchTransfer(from, to, tokenIds);
  }

  function _batchTransfer(
    address from,
    address to,
    uint256[] memory tokenIds
  )
    internal
    virtual
    returns (uint256 amountTransferred)
  {
    uint256 count = tokenIds.length;

    for (uint256 i = 0; i < count; i++) {
      uint256 tokenId = tokenIds[i];

      // Skip invalid tokens; no need to cancel the whole tx for 1 failure
      // These are the exact same "require" checks performed in ERC721.sol for standard transfers.
      if (
        (ownerOf(tokenId) != from) ||
        (!_isApprovedOrOwner(from, tokenId)) ||
        (to == address(0))
      ) { continue; }

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      amountTransferred += 1;
      _owners[tokenId] = to;

      emit Transfer(from, to, tokenId);

      _afterTokenTransfer(from, to, tokenId);
    }

    // We can save a bit of gas here by updating these state-vars atthe end
    _balances[from] -= amountTransferred;
    _balances[to] += amountTransferred;
  }


    /// @notice withdraw ether from contract.
    /// @dev only owner function
    function withdraw() public onlyOwner nonReentrant{          
        (bool owner, ) = payable(owner()).call{value: address(this).balance}('');
        require(owner);    
    }
}
