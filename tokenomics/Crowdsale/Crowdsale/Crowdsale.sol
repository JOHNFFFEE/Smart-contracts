//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Crowdsale is Context, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 public _token;

  // Address where funds are collected
  address payable public _wallet;

  // How many token units a buyer gets per wei.

  uint256 public _rate;

  // Amount of wei raised
  uint256 public _weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  constructor(uint256 rate, address payable wallet, IERC20 token) {
    require(rate > 0, "Crowdsale: rate is 0");
    require(wallet != address(0), "Crowdsale: wallet is the zero address");
    require(
      address(token) != address(0),
      "Crowdsale: token is the zero address"
    );

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

  fallback() external payable {
    buyTokens(msg.sender);
  }

  receive() external payable {
    buyTokens(msg.sender);
  }

  /**
   * @return the token being sold.
   */
  function token() public view returns (IERC20) {
    return _token;
  }

  /**
   * @return the address where funds are collected.
   */
  function wallet() public view returns (address payable) {
    return _wallet;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function rate() public view returns (uint256) {
    return _rate;
  }

  // /**
  //  * @return the amount of wei raised.
  //  */
  // function weiRaised() public view returns (uint256) {
  //     return _weiRaised;
  // }

  function buyTokens(address beneficiary) public payable virtual {
    uint256 weiAmount = msg.value;

    _preValidatePurchase(beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

  /**
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  ) internal virtual {
    require(
      beneficiary != address(0),
      "Crowdsale: beneficiary is the zero address"
    );
    require(weiAmount != 0, "Crowdsale: Non-Sufficient Funds");
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
   * conditions are not met.
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  ) internal view virtual {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
   * its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  ) internal virtual {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
   * tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  ) internal virtual {
    _deliverTokens(beneficiary, tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions,
   * etc.)
   * @param beneficiary Address receiving the tokens
   * @param weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  ) internal virtual {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(
    uint256 weiAmount
  ) internal view virtual returns (uint256) {
    return weiAmount.mul(_rate);
  }

  /**
   * @return Number of tokens left in contract
   */

  function balanceContract() public view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}
