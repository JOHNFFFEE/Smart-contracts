// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract simpleToken is ERC20, Ownable {
    constructor() ERC20("Reward token", "RTK") {
            _mint(msg.sender, 100000 * 18 ** decimals());
    }

}