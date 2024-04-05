// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../Crowdsale.sol";
import "./CapperRole.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IndividuallyCappedCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Crowdsale with per-beneficiary caps.
 */

contract IndividuallyCappedCrowdsale is Crowdsale, CapperRole {
  using Math for uint256;

  mapping(address => uint256) private _contributions;
  mapping(address => uint256) private _caps;

  constructor(
    uint256 _initialRate,
    address payable walletAddress,
    IERC20 _tokenAddress
  ) Crowdsale(_initialRate, walletAddress, _tokenAddress) {}

  /**
   * @dev Sets a specific beneficiary's maximum contribution.
   * @param beneficiary Address to be capped
   * @param cap Wei limit for individual contribution
   */
  function setCap(address beneficiary, uint256 cap) external onlyCapper {
    _caps[beneficiary] = cap;
  }

  /**
   * @dev Returns the cap of a specific beneficiary.
   * @param beneficiary Address whose cap is to be checked
   * @return Current cap for individual beneficiary
   */
  function getCap(address beneficiary) public view returns (uint256) {
    return _caps[beneficiary];
  }

  /**
   * @dev Returns the amount contributed so far by a specific beneficiary.
   * @param beneficiary Address of contributor
   * @return Beneficiary contribution so far
   */
  function getContribution(address beneficiary) public view returns (uint256) {
    return _contributions[beneficiary];
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual override {
    super._preValidatePurchase(beneficiary, weiAmount);
    // solhint-disable-next-line max-line-length
    (bool success, uint256 result) = _contributions[beneficiary].tryAdd(weiAmount);
    require(success);
    require(
      result <= _caps[beneficiary],
      "IndividuallyCappedCrowdsale: beneficiary's cap exceeded"
    );
  }

  /**
   * @dev Extend parent behavior to update beneficiary contributions.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  ) internal virtual override {
    super._updatePurchasingState(beneficiary, weiAmount);
    (bool success, uint256 result) = _contributions[beneficiary].tryAdd(weiAmount);
    require(success);
    _contributions[beneficiary] = result;
  }
}
