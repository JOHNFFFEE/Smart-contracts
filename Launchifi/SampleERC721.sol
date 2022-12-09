
    // SPDX-License-Identifier: MIT


    //   __         ______     __  __     __   __     ______     __  __     __     ______   __    
    //  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
    //  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
    //   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
    //    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

    pragma solidity ^0.8.10;

        
    import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";
    import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
    import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
    import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";    

    
    contract SampleERC721 is ERC721, Ownable, ReentrancyGuard  , DefaultOperatorFilterer {
        using Strings for uint256;
        using Counters for Counters.Counter;
    
        uint256 public price;
        uint256 public _maxSupply;
        uint256 public maxMintAmountPerTx;
        uint256 public maxMintAmountPerWallet;
        string baseURL = "";
        string ExtensionURL = ".json";
        bool paused = false;
        Counters.Counter private _tokenIdCounter;

        string HiddenURL;
         bool whitelistFeature = false;
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
        error InvalidProof();
        
        constructor(uint256 _price, uint256 __maxSupply, string memory _initBaseURI, uint256 _maxMintAmountPerTx, uint256 _maxMintAmountPerWallet, string memory _initNotRevealedUri, bytes32 _hashroot) ERC721("SampleNFT", "SNFT") {
            baseURL = _initBaseURI;
            price = _price;
            _maxSupply = __maxSupply;
            maxMintAmountPerTx = _maxMintAmountPerTx;
            maxMintAmountPerWallet = _maxMintAmountPerWallet;
            HiddenURL = _initNotRevealedUri;
             hashRoot = _hashroot;
             
        }
    
        // ================= Mint Function =======================

        modifier mintCompliance(uint256 _mintAmount) {
            if (msg.sender != tx.origin) revert NoSmartContract();
            if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
            if (currentSupply() + _mintAmount > _maxSupply) revert MaxSupply();
            if (msg.value < price) revert InsufficientFund();
            if(paused) revert ContractPaused();
            if(balanceOf(msg.sender) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
            _;
        }

   
        function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
            if (!whitelistFeature) revert NotWhitelistMintEnabled() ;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if(MerkleProof.verify(_merkleProof, hashRoot, leaf)) revert InvalidProof() ;
            _safeMint(msg.sender, _mintAmount);
        } 

        
        function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)
        {   
     if (whitelistFeature) revert NotWhitelistMintEnabled() ;        
          multiMint(msg.sender, _mintAmount);
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
    
        // =================== Orange Functions (Owner Only) ===============
    
        function pause() public onlyOwner {
            paused = !paused;
        }
    
        function airdrop(address[] memory _receiver, uint _mintAmount ) public onlyOwner{
            if (currentSupply() + (_receiver.length * _mintAmount) > _maxSupply) revert MaxSupply();
            if(paused) revert ContractPaused();
            for (uint i=0 ; i<_receiver.length; i++)
              multiMint(_receiver[i],  _mintAmount);
        }
    
        function setHiddenURL(string memory uri) public onlyOwner {
            HiddenURL = uri;
        }
        
        function setReveal() public onlyOwner {
            revealed = !revealed;
        }
        
    
        function setbaseURL(string memory uri) public onlyOwner{
            baseURL = uri;
        }
    
        function setExtensionURL(string memory uri) public onlyOwner{
            ExtensionURL = uri;
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

        // ================== Withdraw Function =============================
        function withdraw() public onlyOwner nonReentrant{
            
            
            (bool owner, ) = payable(owner()).call{value: address(this).balance}('');
            require(owner);    
        }
    
        // =================== Blue Functions (View Only) ====================
    
        function tokenURI(uint256 tokenId)public view virtual override returns (string memory){
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
        
        function currentSupply() public view returns (uint256){
            return _tokenIdCounter.current();
        }
    
    
        function setCostPrice(uint256 _cost) public onlyOwner{
            price = _cost;
        } 

        // ================ Internal Functions ===================
    
        // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override{
        //     super._beforeTokenTransfer(from, to, tokenId);
        // }

        function multiMint(address _receiver,   uint _mintAmount) internal {
           for (uint256 i = 0; i < _mintAmount; i++){
                _tokenIdCounter.increment();               
                _safeMint(_receiver, _tokenIdCounter.current());
            }
        }    
           function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    } 
    }




    