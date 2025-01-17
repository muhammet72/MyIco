// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../validation/TimedCrowdsale.sol";

/**
 * @title FinalizableCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of TimedCrowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
abstract contract FinalizableCrowdsale is TimedCrowdsale {
  using Math for uint256;

  bool private _finalized;

  event CrowdsaleFinalized();

  constructor() {
    _finalized = false;
  }

  /**
   * @return true if the crowdsale is finalized, false otherwise.
   */
  function finalized() public view returns (bool) {
    return _finalized;
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() public {
    require(!_finalized, "FinalizableCrowdsale: already finalized");
    require(hasClosed(), "FinalizableCrowdsale: not closed");

    _finalized = true;

    _finalization();
    emit CrowdsaleFinalized();
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super._finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function _finalization() internal virtual {
    // solhint-disable-previous-line no-empty-blocks
  }
}
