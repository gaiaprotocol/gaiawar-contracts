// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IUnitManager {
    struct Unit {
        uint16 hp;
        uint16 damage;
        uint8 attackRange;
        uint16 assetVersion;
        uint256[] trainCosts;
        uint256 preUpgradeUnitId;
        uint256 upgradeItemId;
    }

    function getUnit(uint256 unitId) external view returns (Unit memory);
}
