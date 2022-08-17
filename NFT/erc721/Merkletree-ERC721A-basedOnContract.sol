// SPDX-License-Identifier: MIT
// Edited by LAx
//WL mint based on other contract minting
//multiple costs, open/close 


pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract contractName is ERC721A, Ownable, ReentrancyGuard {


  bytes32 public merkleRoot = 0x5465d605c805ef7c9e746a29e0c2c48dd47907674f404710d80564c8611f1f08;
//   mapping(address => bool) public whitelistClaimed;



// ["0xc3e68434234fc62b3a23c40d651dc33e42d292116e8bf882ba184d83f30fb06e"]
  string private uriPrefix ;
  string constant uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public costPublic = 0.000001 ether;
  uint256 public costWL = 0.000001 ether;
  uint256 public maxSupply = 8008;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public maxMintAmountPerWallet = 5;
  uint256 public ownermintAmount = 1;
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public publicMintEnabled = false;
  bool public revealed = false;
  IERC721A public immutable nftCollection;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri,
     string memory MetadataUri,
    IERC721A _nftCollection
  ) ERC721A(_tokenName, _tokenSymbol ) {
     
    setHiddenMetadataUri(_hiddenMetadataUri);
    _mintERC2309(_msgSender(), ownermintAmount);
    nftCollection =_nftCollection ; 
    setUriPrefix(MetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Reached max per trx!');
    require( balanceOf(_msgSender())+ _mintAmount <= maxMintAmountPerWallet, 'Reached max per wallet!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(!paused, 'The contract is paused!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= costWL * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    // require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    require (nftCollection.balanceOf(_msgSender()) >= _mintAmount + balanceOf(_msgSender() ),  'no passes for you available');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    // whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)  {
    require(publicMintEnabled, 'The public sale is not enabled!');     
    require(msg.value >= costPublic * _mintAmount, 'Insufficient funds!');    

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

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

  function setCostPublic(uint256 _cost) public onlyOwner {
    costPublic = _cost;
  }

  function setCostWL(uint256 _cost) public onlyOwner {
    costWL = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled() public onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
  }

  function setPublicMintEnabled() public onlyOwner {
    publicMintEnabled = !publicMintEnabled;
  }  


  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool hs, ) = payable(0x479eec2Ed1Da9Ec2e8467EF1DC72fd9cE848e1C3).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
