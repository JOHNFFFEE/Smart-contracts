// SPDX-License-Identifier: MIT
// Edited by LAx

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract contractName is ERC721A, Ownable, ReentrancyGuard {


  string public uriPrefix = 'ipfs://replace with base uri/';
  string constant uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 8008;
  uint256 public maxMintAmountPerTx = 5;
  bool public paused = true;
  bool public revealed = false;


  error ContractPaused();
  error TokenNotExisting();
  error MaxSupply();
  error InvalidMintAmount();
  error InsufficientFund();


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setHiddenMetadataUri(_hiddenMetadataUri);
      }


  modifier mintCompliance(uint256 _mintAmount) {
      require(msg.sender == tx.origin, "no smart contracts");
    if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
    if (totalSupply() + _mintAmount > maxSupply) revert MaxSupply();
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if (msg.value < cost * _mintAmount) revert InsufficientFund();
    _;
  }


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
   if (paused) revert ContractPaused();
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

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
        ? string(abi.encodePacked(currentBaseURI,  _toString(_tokenId), uriSuffix))
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

//   function setUriSuffix(string memory _uriSuffix) public onlyOwner {
//     uriSuffix = _uriSuffix;
//   }

  function setPaused() public onlyOwner {
    paused = !paused;
  }

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
