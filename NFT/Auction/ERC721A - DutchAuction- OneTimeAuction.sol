// SPDX-License-Identifier: MIT
// Edited by LAx

/*Dutch Auction - one time run auction
* can change the parameters except the startDate , endDate
* better to use the auction parameters as constant to use less gas 
*/

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
// import '@openzeppelin/contracts/utils/Strings.sol';
// import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract contractNameWithStuct is ERC721A, Ownable, ReentrancyGuard {
//   using SafeMath for uint256;
//   using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  uint256 constant private pie = 31415; 
  uint256 constant private mypie = pie/10000;
  string private uriPrefix ;
  string constant uriSuffix = '.json';
  string private hiddenMetadataUri;
  uint256 public wlCost = 0.1 ether;
  uint256 constant public maxSupply = 8008;
  uint256 public maxMintAmountPerTx = 5;
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;



  /////Dutch auction functions -- change to immutable
  struct Dutch_a {
    uint256  d_startPrice;
    uint256  d_startAt;
    uint256  d_endsAt;
    uint256  d_endPrice;
    uint256  discountRate ;
  }

  Dutch_a private auction;


  ///////////////////

  error ContractPaused();
  error TokenNotExisting();
  error MaxSupply();
  error InvalidMintAmount();
  error InsufficientFund();
  error WhitelistClosed(); 
  error AlreadyClaimed();
  error InvalidProof();



   constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setHiddenMetadataUri(_hiddenMetadataUri);
      setAuction();
      }

  modifier mintCompliance(uint256 _mintAmount) {
        // if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();

    if (_mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
    if (totalSupply() + _mintAmount > maxSupply) revert MaxSupply();

    // require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    // require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  // modifier mintPriceCompliance(uint256 _mintAmount) {
  //   if (msg.value < wlCost * _mintAmount) revert InsufficientFund();

  //   // require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
  //   _;
  // }


    function price() public view returns (uint256) {
    if (auction.d_endsAt < block.timestamp) {
        return auction.d_endPrice;
    }

    uint256 minutesElapsed = (block.timestamp - auction.d_startAt) / 60;

    return auction.d_startPrice - (minutesElapsed * auction.discountRate);
    }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount)  {
    if (!whitelistMintEnabled) revert WhitelistClosed();
    // require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    if(whitelistClaimed[_msgSender()]) revert AlreadyClaimed();
    // require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    if(!MerkleProof.verify(_merkleProof, merkleRoot, leaf) ) revert InvalidProof(); 
    // require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    if (msg.value < wlCost * _mintAmount) revert InsufficientFund();

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)  {
    uint getPrice = price();
   if (paused) revert ContractPaused();
   if (msg.value < getPrice * _mintAmount) revert InsufficientFund();

    _safeMint(_msgSender(), _mintAmount);
  }
  
  // function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
  //   _safeMint(_receiver, _mintAmount);
  // }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert TokenNotExisting();
    // require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
        : '';
  }

  function setRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setWlCost(uint256 _cost) public onlyOwner {
    wlCost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUri(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

//   function setUriSuffix(string memory _uriSuffix) public onlyOwner {
//     uriSuffix = _uriSuffix;
//   }

  function setPaused() public onlyOwner {
    paused = !paused;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  ///Dutch auctions parameters

  function setAuctionStartPrice(uint256 _startPrice) public onlyOwner {
    auction.d_startPrice = _startPrice;
  }

  function setAuctionEndPrice(uint256 _endPrice) public onlyOwner {
    auction.d_endPrice = _endPrice;
  }

  function setAuctionDiscountRate(uint256 _discountRate) public onlyOwner {
    auction.discountRate = _discountRate;
  }

//set DutchStart Date
  function setAuction() internal {
    auction =Dutch_a(mypie *10**18 , block.timestamp, block.timestamp * mypie *60  , 1.5 ether , 0.01 ether);
  } 

/////////////

  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}