// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IUnitRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UnitRegistry is IUnitRegistry, OwnableUpgradeable {
    mapping(uint16 => Unit) private units;
    uint16 private nextUnitId;

    event UnitAdded(
        uint16 unitId,
        uint16 hp,
        uint16 damage,
        uint8 attackRange,
        uint16 assetVersion,
        uint256[] trainCosts,
        uint16 preUpgradeUnitId,
        uint16 upgradeItemId
    );

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function getUnit(uint16 unitId) external view override returns (Unit memory) {
        return units[unitId];
    }

    function addUnit(
        uint16 hp,
        uint16 damage,
        uint8 attackRange,
        uint16 assetVersion,
        uint256[] calldata trainCosts,
        uint16 preUpgradeUnitId,
        uint16 upgradeItemId
    ) external onlyOwner {
        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        require(units[unitId].hp == 0, "Unit already exists");

        units[unitId] = Unit({
            hp: hp,
            damage: damage,
            attackRange: attackRange,
            assetVersion: assetVersion,
            trainCosts: trainCosts,
            preUpgradeUnitId: preUpgradeUnitId,
            upgradeItemId: upgradeItemId
        });

        emit UnitAdded(unitId, hp, damage, attackRange, assetVersion, trainCosts, preUpgradeUnitId, upgradeItemId);
    }
}
