// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title WhitelistedRole
 * @author muhammet72  https://github.com/muhammet72
 * @dev Whitelisted accounts have been approved by Owner to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
// THIS CONTRACT NEED TO ADD ROLE INIT IT'S NOT DONE YET
contract WhitelistedRole is Context, AccessControl, Ownable {
  event WhitelistedAdded(bytes32 role, address indexed account);
  event WhitelistedRemoved(bytes32 role, address indexed account);

  modifier onlyWhitelisted() {
    require(
      isWhitelisted(_msgSender()),
      "WhitelistedRole: caller does not have the Whitelisted role"
    );
    _;
  }

  constructor() Ownable(msg.sender) {}

  function isWhitelisted(address account) public view returns (bool) {
    return _hasRole(account);
  }

  function _hasRole(address account) public view returns (bool) {
    bytes32 whitelistedRole;
    return hasRole(whitelistedRole, account);
  }

  function addWhitelisted(address account) public onlyOwner {
    _addWhitelisted(account);
  }

  function removeWhitelisted(address account) public onlyOwner {
    _removeWhitelisted(account);
  }

  function renounceWhitelisted() public {
    _removeWhitelisted(_msgSender());
  }

  function _addWhitelisted(address account) internal {
    bytes32 whitelistedRole;
    _grantRole(whitelistedRole, account);
    emit WhitelistedAdded(whitelistedRole, account);
  }

  function _removeWhitelisted(address account) internal {
    bytes32 whitelistedRole;
    _revokeRole(whitelistedRole, account);
    emit WhitelistedRemoved(whitelistedRole, account);
  }
}
