//SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;


// import"./Crowdsale.sol";
import"@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TimedCrowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
abstract contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   */
  function withdrawTokens() public {
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal virtual override 
  {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

}
