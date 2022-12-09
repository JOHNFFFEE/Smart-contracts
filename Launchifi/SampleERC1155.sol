
// SPDX-License-Identifier: MIT


//   __         ______     __  __     __   __     ______     __  __     __     ______   __    
//  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
//  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
//   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
//    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract SampleERC1155 is ERC1155,Pausable,  Ownable, ERC1155Supply {



    bool public revealed = false;
    uint maxPerWallet=  5;
    uint maxTransaction = 3;
    uint price= 0.05 ether;
    string public name;
    string public symbol;


    constructor( string memory CollectionName, string memory CollectionSymble , string memory _initNotRevealedUri) ERC1155("ipfs://bb/") {
    name = CollectionName;
    symbol = CollectionSymble;

    _mint(msg.sender,  0, 0, "0x0");     

    }


    

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }



    function reveal() public onlyOwner {
       revealed = true;
    }


    modifier limitPerWallet (uint256 id, uint256 amount) {
          require(amount <= maxPerWallet, "Exceeded limit per wallet" );
          require( balanceOf(msg.sender, id) + amount <= maxPerWallet,"Exceeded limit per wallet");
        _;
    }


    modifier limitPerTrx (uint256 amount) {
        require(amount<=maxTransaction, "Exceeded limit per trx" );
        _;
    }


    function mint(uint256 id, uint256 amount)
        public payable    limitPerWallet(id, amount)    limitPerTrx(amount)
    {  
          require(msg.value >= price*amount,"Not enough money");
        require(msg.sender == tx.origin, "no smart contracts");             
        _mint(msg.sender, id, amount, " ");
    }
      
   function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
        _burnBatch(_from, _burnIds, _burnAmounts);
        _mintBatch(_from, _mintIds, _mintAmounts, "");
    }
 


    function setURI(string memory newuri) public onlyOwner {
        require(revealed, "Collection not revealed");
        _setURI(newuri);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

        function withdraw() public payable onlyOwner {    
        require(address(this).balance>0, "Not enough balance");
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    
     }
}



    