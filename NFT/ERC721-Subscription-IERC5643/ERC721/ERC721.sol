// SPDX-License-Identifier: CCO

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC5643.sol";

contract Modified_ERC5643 is ERC721, IERC5643, Ownable {
    mapping(uint256 => uint64) private _subscriptions;

    uint64 expir = uint64(now() +50) ;
    uint cost = 0.5 ether ;   
     

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

        function mint(address to, uint256 tokenId) public payable  {
        _mint(to, tokenId);
        renewSubscription(tokenId,expir);
    }

    function renewSubscription(uint256 tokenId, uint64 expiration) public payable {
        require(msg.value>= cost, 'Not Enough Funds');
        _subscriptions[tokenId] = expiration;
        emit SubscriptionUpdate(tokenId, expiration);
    }

    function cancelSubscription(uint256 tokenId) external onlyOwner {
        delete _subscriptions[tokenId];
        emit SubscriptionUpdate(tokenId, 0);
    }

    function expiresAt(uint256 tokenId) external view returns(uint64) {
        return _subscriptions[tokenId];
    }

    function isRenewable(uint256 tokenId) external pure returns(bool) {
        return true;
    }

    function isExpired(uint256 tokenId) external view returns(bool expired) {
        if  (  _subscriptions[tokenId]<= now() )
        return true;

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5643).interfaceId || super.supportsInterface(interfaceId);
    }

    function now() view public returns (uint time){
        return  block.timestamp;
    }

}
