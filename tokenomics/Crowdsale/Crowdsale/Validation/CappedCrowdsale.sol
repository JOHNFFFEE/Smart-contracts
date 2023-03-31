//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) {
    require(_cap > 0, "zero cap");
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached(uint weiRaised) public view returns (bool) {
    return weiRaised >= cap;
  }
}
