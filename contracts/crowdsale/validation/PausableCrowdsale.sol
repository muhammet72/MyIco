// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title PausableCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of Crowdsale contract where purchases can be paused and unpaused by the pauser role.
 */
abstract contract PausableCrowdsale is Crowdsale, Pausable {
  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
   * Use super to concatenate validations.
   * Adds the validation that the crowdsale must not be paused.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal override whenNotPaused {
    return super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}
