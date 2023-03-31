
// SPDX-License-Identifier: MIT

           
pragma solidity >=0.8.13 <0.9.0;

   import "./Crowdsale.sol";
   import "./TimedCrowdsale.sol";
   import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
 
 contract MyCrowdsale is Crowdsale, TimedCrowdsale {
    constructor(
        uint256 rate,
        address payable wallet,
        IERC20 token, 
        uint256 openingTime,     // opening time in unix epoch seconds
        uint256 closingTime 
    )  Crowdsale(rate, wallet, token)
    TimedCrowdsale(openingTime, closingTime){} 

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        ERC20PresetMinterPauser(address(token())).mint(beneficiary, tokenAmount);
    }  

     function _preValidatePurchase (
    address _beneficiary,
    uint256 _weiAmount
  )
    internal  override  (Crowdsale ,TimedCrowdsale)  virtual  
    onlyWhileOpen
  {
    Crowdsale._preValidatePurchase(_beneficiary, _weiAmount);   
  }


 
 }
 
 // The contract erc20 should be deployed and be mintable and mint onlyowner
 // rate  - number of token*18 per wei
 //wallet - who should receive the founds
 
