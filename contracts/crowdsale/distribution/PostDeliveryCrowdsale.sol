// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../helpers/Secondary.sol";

/**
 * @title PostDeliveryCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */
abstract contract PostDeliveryCrowdsale is TimedCrowdsale {
  using Math for uint256;

  event WithdrawedTokens(address acount, uint amount);

  mapping(address => uint256) private _balances;
  __unstable__TokenVault private _vault;

  constructor() {
    _vault = new __unstable__TokenVault();
  }

  /**
   * @dev Withdraw tokens only after crowdsale ends.
   * @param beneficiary Whose tokens will be withdrawn.
   */
  function withdrawTokens(address beneficiary) public virtual {
    require(hasClosed(), "PostDeliveryCrowdsale: not closed");
    uint256 amount = _balances[beneficiary];
    require(amount > 0, "PostDeliveryCrowdsale: beneficiary is not due any tokens");

    _balances[beneficiary] = 0;
    _vault.transfer(token(), beneficiary, amount);
    emit WithdrawedTokens(beneficiary, amount);
  }

  /**
   * @return the balance of an account.
   */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Overrides parent by storing due balances, and delivering tokens to the vault instead of the end user. This
   * ensures that the tokens will be available by the time they are withdrawn (which may not be the case if
   * `_deliverTokens` was called later).
   * @param beneficiary Token purchaser
   * @param tokenAmount Amount of tokens purchased
   */
  function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual override {
    (bool success, uint256 result) = _balances[beneficiary].tryAdd(tokenAmount);
    require(success);
    _balances[beneficiary] = result;
    _deliverTokens(address(_vault), tokenAmount);
  }
}

/**
 * @title __unstable__TokenVault
 * @dev Similar to an Escrow for tokens, this contract allows its primary account to spend its tokens as it sees fit.
 * This contract is an internal helper for PostDeliveryCrowdsale, and should not be used outside of this context.
 */
// solhint-disable-next-line contract-name-camelcase
// Ownable2Step
contract __unstable__TokenVault is Secondary {
  // constructor(address initialOwner) Ownable(initialOwner) {}

  function transfer(IERC20 token, address to, uint256 amount) public onlyPrimary {
    token.transfer(to, amount);
  }
}
