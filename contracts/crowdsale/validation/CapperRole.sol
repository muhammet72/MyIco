// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title CapperRole
 * @author muhammet72  https://github.com/muhammet72
 */

contract CapperRole is Context, AccessControl {
  event CapperAdded(bytes32 role, address indexed account);
  event CapperRemoved(bytes32 role, address indexed account);

  constructor() {
    _addCapper(_msgSender());
  }

  modifier onlyCapper() {
    require(isCapper(_msgSender()), "CapperRole: caller does not have the Capper role");
    _;
  }

  function isCapper(address account) public view returns (bool) {
    return _hasRole(account);
  }

  function _hasRole(address account) public view returns (bool) {
    bytes32 capperRole;
    return hasRole(capperRole, account);
  }

  function addCapper(address account) public onlyCapper {
    _addCapper(account);
  }

  function renounceCapper() public {
    _removeCapper(_msgSender());
  }

  function _addCapper(address account) internal {
    bytes32 capperRole;
    _grantRole(capperRole, account);
    emit CapperAdded(capperRole, account);
  }

  function _removeCapper(address account) internal {
    bytes32 capperRole;
    _revokeRole(capperRole, account);
    emit CapperRemoved(capperRole, account);
  }
}
