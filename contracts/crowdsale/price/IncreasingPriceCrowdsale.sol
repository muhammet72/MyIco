// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title IncreasingPriceCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of Crowdsale contract that increases the price of tokens linearly in time.
 * Note that what should be provided to the constructor is the initial and final _rates_, that is,
 * the amount of tokens per wei contributed. Thus, the initial rate must be greater than the final rate.
 */
abstract contract IncreasingPriceCrowdsale is TimedCrowdsale {
  using Math for uint256;

  uint256 private _initialRate;
  uint256 private _finalRate;

  /**
   * @dev Constructor, takes initial and final rates of tokens received per wei contributed.
   * @param initial_Rate Number of tokens a buyer gets per wei at the start of the crowdsale
   * @param final_Rate Number of tokens a buyer gets per wei at the end of the crowdsale
   */
  constructor(uint256 initial_Rate, uint256 final_Rate) {
    require(final_Rate > 0, "IncreasingPriceCrowdsale: final rate is 0");
    // solhint-disable-next-line max-line-length
    require(
      initial_Rate > final_Rate,
      "IncreasingPriceCrowdsale: initial rate is not greater than final rate"
    );
    _initialRate = initial_Rate;
    _finalRate = final_Rate;
  }

  /**
   * The base rate function is overridden to revert, since this crowdsale doesn't use it, and
   * all calls to it are a mistake.
   */
  function rate() public pure override returns (uint256) {
    revert("IncreasingPriceCrowdsale: rate() called");
  }

  /**
   * @return the initial rate of the crowdsale.
   */
  function initialRate() public view returns (uint256) {
    return _initialRate;
  }

  /**
   * @return the final rate of the crowdsale.
   */
  function finalRate() public view returns (uint256) {
    return _finalRate;
  }

  /**
   * @dev Returns the rate of tokens per wei at the present time.
   * Note that, as price _increases_ with time, the rate _decreases_.
   * @return The number of tokens a buyer gets per wei at a given time
   */
  function getCurrentRate() public view returns (uint256) {
    if (!isOpen()) {
      return 0;
    }

    // solhint-disable-next-line not-rely-on-time
    // solhint-disable-next-line not-rely-on-time
    (bool success1, uint256 result1) = block.timestamp.trySub(getOpeningTime());
    require(success1);
    uint256 elapsedTime = result1;

    (bool success2, uint256 result2) = getClosingTime().trySub(getOpeningTime());
    require(success2);
    uint256 timeRange = result2;

    (bool success3, uint256 result3) = _initialRate.trySub(_finalRate);
    require(success3);
    uint256 rateRange = result3;

    (bool success4, uint256 result4) = _initialRate.trySub(
      (elapsedTime * rateRange) / (timeRange)
    );
    require(success4);
    return result4;
  }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will buy at present time
   */
  function _getTokenAmount(uint256 weiAmount) internal view override returns (uint256) {
    uint256 currentRate = getCurrentRate();
    (bool success, uint256 result) = currentRate.tryMul(weiAmount);
    require(success);
    return result;
  }
}
