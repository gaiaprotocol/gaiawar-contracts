// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract UnitManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct UnitSpec {
        uint16 hp;
        uint16 damage;
        uint8 attackRange;
    }

    struct TrainCost {
        uint16 assetVersion;
        uint256[] amounts;
    }

    struct UpgradeSpec {
        uint16 targetUnitId;
        uint16 assetVersion;
        uint256 itemId;
    }

    mapping(uint16 => UnitSpec) public unitSpecs; // unitId => unitSpec
    mapping(uint16 => TrainCost) public trainCosts; // unitId => costs
    mapping(uint16 => UpgradeSpec) public upgradeCosts; // unitId => costs
}
