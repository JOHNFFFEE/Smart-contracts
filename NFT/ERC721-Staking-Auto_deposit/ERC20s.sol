// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20s is ERC20, Ownable {

     mapping (address => bool) public allowed ;
    constructor() ERC20("MyToken", "MTK") {}

    function mint( address _to , uint256 amount) public  {
        require (allowed[msg.sender], "Not owner");
        _mint(_to, amount);
    }



    function addAllowed( address _stakingContract) public onlyOwner  {
        allowed[_stakingContract]= true;
        
    }


}
