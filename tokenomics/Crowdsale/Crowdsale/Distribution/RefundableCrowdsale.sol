//SPDX-License-Identifier: MIT
//buggy

pragma solidity ^0.8.17;

// import"./Crowdsale.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./FinalizableCrowdsale.sol";
import "./utils/RefundVault.sol";

/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale's vault.
 */
abstract contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  /**
   * @dev Constructor, creates RefundVault.
   * @param _goal Funding goal
   */
  constructor(uint256 _goal) payable {
    require(_goal > 0);
    vault = new RefundVault(wallet());
    goal = _goal;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public payable {
    require(isFinalized);
    require(!goalReached());
    vault.refund(payable(msg.sender));
  }

  /**
   * @dev Checks whether funding goal was reached.
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return _weiRaised >= goal;
  }

  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal virtual override {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */

  //  (bool os, ) = payable(owner()).call{value: address(this).balance}('');
  // require(os);

  function _forwardFunds() internal virtual override {
    vault.deposit{ value: msg.value }(msg.sender);
  }
}
