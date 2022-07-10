// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract MyRoyalities is ERC721, ERC721Enumerable, ERC2981, Ownable {
    string public contractURI;
    uint96 royaltyFraction;
    uint salePrice = 0.5 ether ;

 /**
     * @dev _royaltyFeesInBips - the royalities for all NFT
     */    

    constructor(uint96 _royaltyFeesInBips, string memory _contractURI) ERC721("MyToken", "MTK") {
        setRoyaltyInfo(owner(), _royaltyFeesInBips);
        royaltyFraction = _royaltyFeesInBips ;
        contractURI = _contractURI;
    }

    function safeMint(address to, uint256 tokenId) public payable  {
        if (msg.sender != owner()){
        require (msg.value >= salePrice, 'Not enough Eth');
        }
        _safeMint(to, tokenId);
        //  payable(owner()).transfer( msg.value * royaltyFraction / 100);
    }


 /**
     * @dev _setDefaultRoyalty - set royalities for all collection 
     */

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

 /**
     * @dev _setTokenRoyalty - set royalities for each tokenId 
     */

    function setRoyaltyTokens(uint _tokenId, address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setTokenRoyalty(_tokenId ,_receiver, _royaltyFeesInBips);
    }

 /**
     * @dev _feeDenominator - set percentage where it is calculated
     */
    function _feeDenominator() internal override virtual pure returns (uint96) {
        return 100;
    }



    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        payable(owner()).transfer( msg.value * royaltyFraction / 100); //mint included
    }


    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // function _afterTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal override  {

    //  super._afterTokenTransfer(from, to, tokenId);
    //    payable(owner()).transfer( msg.value * royaltyFraction / 100); //mint included
    // }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}