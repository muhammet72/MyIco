// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RefundableCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";

/**
 * @title RefundablePostDeliveryCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of RefundableCrowdsale contract that only delivers the tokens
 * once the crowdsale has closed and the goal met, preventing refunds to be issued
 * to token holders.
 */
abstract contract RefundablePostDeliveryCrowdsale is RefundableCrowdsale, PostDeliveryCrowdsale {
  constructor(uint256 _goal) RefundableCrowdsale(_goal) {}

  function _forwardFunds() internal virtual override(RefundableCrowdsale, Crowdsale) {
    RefundableCrowdsale._forwardFunds();
  }

  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  ) internal virtual override(Crowdsale, PostDeliveryCrowdsale) {
    PostDeliveryCrowdsale._processPurchase(beneficiary, tokenAmount);
  }

  function withdrawTokens(address beneficiary) public virtual override {
    require(finalized(), "RefundablePostDeliveryCrowdsale: not finalized");
    require(goalReached(), "RefundablePostDeliveryCrowdsale: goal not reached");

    super.withdrawTokens(beneficiary);
  }
}
