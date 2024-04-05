// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title IcoToken
 * @author muhammet72  https://github.com/muhammet72
 * @notice
 */

contract IcoToken is ERC20, ERC20Pausable, Ownable, ERC20Permit {
  event Minted(address to, uint256 amount);
  event MintFinished();

  constructor(
    // address initialOwner,
    string memory name_,
    string memory symbol_,
    uint256 premint
  ) ERC20(name_, symbol_) Ownable(msg.sender) ERC20Permit(name_) {
    _mint(msg.sender, premint * 10 ** decimals());
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to, uint256 amount) public onlyOwner returns (bool) {
    _mint(to, amount);
    emit Minted(to, amount);
    return true;
  }

  // The following functions are overrides required by Solidity.

  function _update(
    address from,
    address to,
    uint256 value
  ) internal override(ERC20, ERC20Pausable) {
    super._update(from, to, value);
  }
}
