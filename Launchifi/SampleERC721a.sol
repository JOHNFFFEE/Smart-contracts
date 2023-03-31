
        // SPDX-License-Identifier: MIT


        //   __         ______     __  __     __   __     ______     __  __     __     ______   __    
        //  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
        //  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
        //   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
        //    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

        pragma solidity ^0.8.10;

        import "@openzeppelin/contracts/access/Ownable.sol";
        import "erc721a/contracts/ERC721A.sol";
        import "@openzeppelin/contracts/utils/Strings.sol";
        import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
        import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
        import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
        
        contract SampleERC721a is ERC721A, Ownable, ReentrancyGuard  , DefaultOperatorFilterer {

            using Strings for uint256;       

            uint256 public price;
            uint256 _maxSupply;
            uint256 maxMintAmountPerTx;
            uint256 maxMintAmountPerWallet;
            
            string baseURL = "";
            string ExtensionURL = ".json";
            bool paused = false;
            string HiddenURL;
             bool public whitelistFeature = false;
             bytes32 hashRoot;
             bool revealed = false;
            


            error ContractPaused();
            error MaxMintWalletExceeded();
            error MaxSupply();
            error InvalidMintAmount();
            error InsufficientFund();
            error NoSmartContract();
            error TokenNotExisting();
            error NotWhitelistMintEnabled();
            error AlreadyClaim();
            error InvalidProof();

            constructor(uint256 _price, uint256 __maxSupply, string memory _initBaseURI, uint256 _maxMintAmountPerTx, uint256 _maxMintAmountPerWallet, string memory _initNotRevealedUri, bytes32 _hashroot) ERC721A("SAMPLEnft", "SNFT") {

                baseURL = _initBaseURI;
                price = _price;
                _maxSupply = __maxSupply;
                maxMintAmountPerTx = _maxMintAmountPerTx;
                maxMintAmountPerWallet = _maxMintAmountPerWallet;
                HiddenURL = _initNotRevealedUri;
                hashRoot = _hashroot;
            }

            modifier mintCompliance(uint256 _mintAmount) {
                if (msg.sender != tx.origin) revert NoSmartContract();
                if (totalSupply()  + _mintAmount > _maxSupply) revert MaxSupply();
                if(paused) revert ContractPaused();
            _;
        }

            modifier mintPriceCompliance(uint256 _mintAmount) {
                if(balanceOf(_msgSender()) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
                if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
                if (msg.value < price * _mintAmount) revert InsufficientFund();              
            _;
        }

            // ================== Mint Function =======================

             function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
                if (!whitelistFeature) revert NotWhitelistMintEnabled() ;
                bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
                if(MerkleProof.verify(_merkleProof, hashRoot, leaf)) revert InvalidProof() ;
                _safeMint(_msgSender(), _mintAmount);
            }  

            function mint(uint256 _mintAmount) public payable  mintCompliance(_mintAmount)  mintPriceCompliance(_mintAmount) {                           
              if (whitelistFeature) revert NotWhitelistMintEnabled() ;   
              _safeMint(_msgSender(), _mintAmount);
            }

            // ================== Orange Functions (Owner Only) ===============

            function pause() public onlyOwner {
                paused = !paused;
            }

            function safeMint(address to, uint256 quantity) public onlyOwner mintCompliance(quantity) {
                _safeMint(to, quantity);
            }

      function airdrop(address[] memory _receiver, uint256 _mintAmount) public onlyOwner mintCompliance(_mintAmount){
          for (uint256 i = 0; i < _receiver.length; i++) {
              safeMint(_receiver[i], _mintAmount);  
          }
      }
            
            function setRevealed() public onlyOwner {
                revealed = !revealed;
            }
            
            function setbaseURL(string memory uri) public onlyOwner{
                baseURL = uri;
            }

            function setExtensionURL(string memory uri) public onlyOwner{
                ExtensionURL = uri;
            }

            function setCostPrice(uint256 _cost) public onlyOwner{
                price = _cost;
            }

            function setMaxSupply(uint256 supply) public onlyOwner{
                _maxSupply = supply;
              }
      
              function setMaxMintAmountPerTx(uint256 perTx) public onlyOwner{
                maxMintAmountPerTx = perTx;
              }
      
              function setMaxMintAmountPerWallet(uint256 perWallet) public onlyOwner{
                maxMintAmountPerWallet = perWallet;
              } 

            function _startTokenId() internal view virtual override returns (uint256) {
                return 1;
            }

            
            // ====================== Whitelist Feature ============================

            function setwhitelistFeature() public onlyOwner{
                whitelistFeature = !whitelistFeature;
            }

            function setHashRoot(bytes32 hp)public onlyOwner{
                hashRoot = hp;
            }

            function checkHashRoot() view public onlyOwner returns (bytes32){
                return hashRoot;
            }
            
            // ================================ Withdraw Function ====================

            function withdraw() public onlyOwner nonReentrant{
                uint _balance = address(this).balance;
                            
                (bool owner, ) = payable(owner()).call{value: _balance}('');
                require(owner);                      
            }

            // =================== Blue Functions (View Only) ====================

            function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory){

                if (!_exists(tokenId)) revert TokenNotExisting();
                
                if (revealed == false) {
                return HiddenURL;
                }
                
                string memory currentBaseURI = _baseURI();
                return bytes(currentBaseURI).length > 0
                    ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ExtensionURL))
                    : '';
            }

            function _baseURI() internal view virtual override returns (string memory) {
                return baseURL;
            }

            function maxSupply() public view returns (uint256){
                return _maxSupply;
            }

      
            function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
            super.transferFrom(from, to, tokenId);
            }

            function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId);
            }

            function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
            public payable
            override
            onlyAllowedOperator(from)
            {
            super.safeTransferFrom(from, to, tokenId, data);
            } 
            
 
        }      
        