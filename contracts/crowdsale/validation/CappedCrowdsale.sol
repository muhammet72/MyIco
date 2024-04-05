// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
  using Math for uint256;

  uint256 internal cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   *
   */
  constructor(uint256 _cap) {
    require(_cap > 0, "CappedCrowdsale: cap is 0");
    cap = _cap;
  }

  /**
   * @return the cap of the crowdsale.
   */
  function getCap() public view returns (uint256) {
    return cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised() >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual override {
    super._preValidatePurchase(beneficiary, weiAmount);
    (bool success, uint256 result) = weiRaised().tryAdd(weiAmount);
    require(success);
    require(result <= cap, "CappedCrowdsale: cap exceeded");
  }
}
