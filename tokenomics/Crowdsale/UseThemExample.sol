
// SPDX-License-Identifier: MIT

           
pragma solidity >=0.8.13 <0.9.0;

    import "./Crowdsale.sol";
    import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
   
 contract MyCrowdsale is Crowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token
    )  Crowdsale(rate, wallet, token){}

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        ERC20PresetMinterPauser(address(token())).mint(beneficiary, tokenAmount);
}
 
 }
 
 // The contract erc20 should be deployed and be mintable and mint onlyowner
 // rate  - number of token*18 per wei
 //wallet - who should receive the founds
 
