// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IUnitManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract UnitManager is IUnitManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {}
