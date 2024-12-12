// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IUnitRegistry {
    struct Unit {
        uint16 hp;
        uint16 damage;
        uint8 attackRange;
        uint16 assetVersion;
        uint256[] trainCosts;
        uint16 preUpgradeUnitId;
        uint16 upgradeItemId;
    }

    function getUnit(uint16 unitId) external view returns (Unit memory);
}
