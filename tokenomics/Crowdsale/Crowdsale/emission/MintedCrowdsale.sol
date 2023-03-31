//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../Crowdsale.sol";

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
abstract contract MintedCrowdsale is Crowdsale {
  constructor(
    uint256 rate,
    address payable wallet,
    IERC20 token
  ) Crowdsale(rate, wallet, token) {}

  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  ) internal override {
    ERC20PresetMinterPauser(address(token())).mint(beneficiary, tokenAmount);
  }
}
