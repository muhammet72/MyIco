// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AllowanceCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 */
contract AllowanceCrowdsale is Crowdsale {
  using Math for uint256;
  using SafeERC20 for IERC20;

  address private _tokenWallet;

  /**
   * @dev Constructor, takes token wallet address.
   * @param tokenWallett Address holding the tokens, which has approved allowance to the crowdsale.
   */
  constructor(
    uint256 _initialRate,
    address payable walletAddress,
    IERC20 _tokenAddress,
    address tokenWallett
  ) Crowdsale(_initialRate, walletAddress, _tokenAddress) {
    require(tokenWallett != address(0), "AllowanceCrowdsale: token wallet is the zero address");
    _tokenWallet = tokenWallett;
  }

  /**
   * @return the address of the wallet that will hold the tokens.
   */
  function tokenWallet() public view returns (address) {
    return _tokenWallet;
  }

  /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return
      Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
  }

  /**
   * @dev Overrides parent behavior by transferring tokens from wallet.
   * @param beneficiary Token purchaser
   * @param tokenAmount Amount of tokens purchased
   */
  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
    token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
  }
}
