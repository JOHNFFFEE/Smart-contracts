//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Context, Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen() {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime, "Sales not opened yet");
    require(block.timestamp <= closingTime, "Sales already closed");
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp, "Sales Not opened yet");
    require(
      _closingTime >= _openingTime,
      "closingTime should be bigger than openingTime"
    );

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal virtual override onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}
