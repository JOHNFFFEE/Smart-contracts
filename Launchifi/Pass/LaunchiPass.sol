
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


/// @title LaunchiFiPass
/// @author LAx
/// @notice Use this contract for only the most basic simulation
/// @dev Contract under development to enable floating point



import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC5643.sol";

contract LaunchiPass is ERC1155,  Ownable, ERC1155Supply, IERC5643 {

    using Counters for Counters.Counter;
    Counters.Counter public passId;

    // uint price = 0.05 ether ;
  
    struct Passes {
        string name ;
        uint price;
        uint64 expr;
        uint amount ;
    }

//Contain all the passes
    mapping(uint256 => Passes) public Pass;

// 1 week  604800 
// 6 months 15778800
// 1 year 31557600

//tokenID
    mapping(uint256 => mapping(address => Passes)) public _subscriptionsbyAddress;

    // uint maxPerWallet=  0;
    // uint maxTransaction = 0;
    string public name;
    string public symbol;


    constructor( string memory CollectionName, string memory CollectionSymbole ) ERC1155("") {
    name = CollectionName;
    symbol = CollectionSymbole;
    }

    /// @notice mint and generate Pass
    /// @param id tokenId
    function mint(uint256 id )
        public payable 
    {           
        require(msg.sender == tx.origin, "no smart contracts");             
        _mint(msg.sender, id, 1, " ");
         renewSubscription(id);
    } 


    /// @notice create a Pass
    /// @dev adding to the struct
    /// @param _name name of the Pass
    /// @param _price price of the Pass in wei
    ///@param _expr lenght of the pass - month , year
    ///@param _amount amount of the Pass tokens
    function newPass(  string calldata _name , uint _price,  uint64 _expr, uint _amount) public  onlyOwner {
        passId.increment();
        uint256 tokenId = passId.current();        
        Pass[tokenId] = Passes(
            _name,
            _price,
            _expr ,
            _amount    
        );
    }
 
 /// @notice create a Pass subscription
    function renewSubscription(uint tokenId) public payable {      
        require(msg.value>= Pass[tokenId].price, 'Not Enough Funds');
        require(totalSupply(tokenId)<= Pass[tokenId].amount , 'No Pass Available' );
        _subscriptionsbyAddress[tokenId][msg.sender].expr = uint64(block.timestamp) + Pass[tokenId].expr;
        emit SubscriptionUpdate(tokenId);
    }

 //onlyOnwer
    function cancelSubscription(uint256 _tokenId , address _user) external onlyOwner {
        delete  _subscriptionsbyAddress[_tokenId][_user] ;
        emit SubscriptionUpdate(_tokenId);
    }

    
    function changePass(uint _tokenId, uint _newAmount, uint _newPrice, uint64 _expr) public onlyOwner {
        Pass[_tokenId].amount = _newAmount ;
        Pass[_tokenId].price = _newPrice ;
        Pass[_tokenId].expr = _expr ;

    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

      /// @notice withdraw money
    function withdraw() public payable onlyOwner {    
        require(address(this).balance>0, "Not enough balance");
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    
    }


    //view 

    function expiresAt(uint256 _tokenId, address _user) external view returns(uint64) {
        return   _subscriptionsbyAddress[_tokenId][_user].expr;
    }

    function isRenewable(uint256 tokenId) external pure returns(bool) {
        return true;
    }

    function isExpired(uint256 _tokenId , address _user) external view returns(bool expired) {
        if  (  _subscriptionsbyAddress[_tokenId][_user].expr<= block.timestamp )
        return true;

    }

      //internal
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }



}
