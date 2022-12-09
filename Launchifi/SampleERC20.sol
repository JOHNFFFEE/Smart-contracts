
// SPDX-License-Identifier: MIT


//   __         ______     __  __     __   __     ______     __  __     __     ______   __    
//  /\ \       /\  __ \   /\ \/\ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\ /\ \   
//  \ \ \____  \ \  __ \  \ \ \_\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \ \  \ \  __\ \ \ \  
//   \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\  \ \_\    \ \_\ 
//    \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/   \/_/     \/_/ 

pragma solidity ^0.8.10;

 import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";   
 import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
 import "@openzeppelin/contracts/security/Pausable.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";

        contract SampleERC20 is ERC20Capped , ERC20Burnable , Pausable, Ownable {
   
        constructor(uint256 cap) ERC20("SampleToken", "SMPL") ERC20Capped(cap){

            _mint(msg.sender,1000*10**decimals())  ;
         }     

     
          function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }

      function _mint(address account, uint256 amount) internal virtual override (ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
 

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function airdrop(  address[] memory add, uint256 amount) onlyOwner external {
    for (uint i=0 ; i< add.length; i++) 
    {
     _mint(add[i], amount);
    }
    }    
   
    /**
    * @dev withdraw ether from contract.
    */  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  } 

}

      
        