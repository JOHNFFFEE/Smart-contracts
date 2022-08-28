// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract YourNftToken is ERC721AQueryable, Ownable, ReentrancyGuard {

//   using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  error ContractPaused();
  error TokenNotExisting();
  error MaxSupply();
  error InvalidMintAmount();
  error InsufficientFund();
  error WlnotEnabled();
  error AlreadyClaimed();



  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
    if (totalSupply() + _mintAmount > maxSupply) revert MaxSupply();
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if (msg.value < cost * _mintAmount) revert InsufficientFund();
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    if (!whitelistMintEnabled) revert WlnotEnabled();
    if (whitelistClaimed[_msgSender()]) revert AlreadyClaimed();
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
   if (paused) revert ContractPaused();

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function Airdrop(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    if (paused) revert ContractPaused();
    _safeMint(_receiver, _mintAmount);
  }


   function AirdropBatch(uint256 _mintAmount, address[] calldata _receiver) public mintCompliance(_mintAmount) onlyOwner {
    if (paused) revert ContractPaused();
    for (uint i ; i<_receiver.length; i++){
          _safeMint(_receiver[i], _mintAmount); 
    } 
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId)) revert TokenNotExisting();

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI,  _toString(tokenId), uriSuffix))
        : '';
  }

  function setRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused() public onlyOwner {
    paused = !paused;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
   
    (bool lx, ) = payable(0x479eec2Ed1Da9Ec2e8467EF1DC72fd9cE848e1C3).call{value: address(this).balance * 5 / 100}('');
    require(lx);
  
    (bool bs, ) = payable(owner()).call{value: address(this).balance}('');
    require(bs);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}