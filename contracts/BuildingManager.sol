// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IBuildingManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract BuildingManager is IBuildingManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {}
