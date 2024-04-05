// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../Crowdsale.sol";

/**
 * @title TimedCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Crowdsale accepting contributions only within a time frame.
 */
abstract contract TimedCrowdsale is Crowdsale {
  using Math for uint256;

  uint256 internal openingTime;
  uint256 internal closingTime;

  /**
   * Event for crowdsale extending
   * @param newClosingTime new closing time
   * @param prevClosingTime old closing time
   */
  event TimedCrowdsaleExtended(uint256 prevClosingTime, uint256 newClosingTime);

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen() {
    require(isOpen(), "TimedCrowdsale: not open");
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) {
    // solhint-disable-next-line not-rely-on-time
    require(
      _openingTime >= block.timestamp,
      "TimedCrowdsale: opening time is before current time"
    );
    // solhint-disable-next-line max-line-length
    require(
      _closingTime > _openingTime,
      "TimedCrowdsale: opening time is not before closing time"
    );

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @return the crowdsale opening time.
   */
  function getOpeningTime() public view returns (uint256) {
    return openingTime;
  }

  /**
   * @return the crowdsale closing time.
   */
  function getClosingTime() public view returns (uint256) {
    return closingTime;
  }

  /**
   * @return true if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period.
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  ) internal virtual override onlyWhileOpen {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

  /**
   * @dev Extend crowdsale.
   * @param newClosingTime Crowdsale closing time
   */
  function _extendTime(uint256 newClosingTime) internal {
    require(!hasClosed(), "TimedCrowdsale: already closed");
    // solhint-disable-next-line max-line-length
    require(
      newClosingTime > closingTime,
      "TimedCrowdsale: new closing time is before current closing time"
    );

    emit TimedCrowdsaleExtended(closingTime, newClosingTime);
    closingTime = newClosingTime;
  }
}
