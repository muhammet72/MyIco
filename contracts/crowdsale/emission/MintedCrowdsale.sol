// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Crowdsale.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../IcoToken.sol";

/**
 * @title MintedCrowdsale
 * @author muhammet72  https://github.com/muhammet72
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
abstract contract MintedCrowdsale is Crowdsale {
  IcoToken internal mintableToken;

  constructor(IcoToken _mintableToken) {
    require(address(_mintableToken) != address(0), "Crowdsale: token is the zero address");
    mintableToken = IcoToken(_mintableToken);
  }

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param beneficiary Token purchaser
   * @param tokenAmount Number of tokens to be minted
   */

  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual override {
    // Potentially dangerous assumption about the type of the token.
    require(mintableToken.mint(beneficiary, tokenAmount), "MintedCrowdsale: minting failed");
  }

  function getMintableToken() public view returns (address) {
    return address(mintableToken);
  }
}
