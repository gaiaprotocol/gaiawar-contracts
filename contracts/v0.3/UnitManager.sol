// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IUnitManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UnitManager is IUnitManager, OwnableUpgradeable {
    mapping(uint256 => Unit) private units;
    uint256 private nextUnitId;

    event UnitAdded(
        uint256 unitId,
        uint16 hp,
        uint16 damage,
        uint8 attackRange,
        uint16 assetVersion,
        uint256[] trainCosts,
        uint256 preUpgradeUnitId,
        uint256 upgradeItemId
    );

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function getUnit(uint256 unitId) external view override returns (Unit memory) {
        return units[unitId];
    }

    function addUnit(
        uint16 hp,
        uint16 damage,
        uint8 attackRange,
        uint16 assetVersion,
        uint256[] calldata trainCosts,
        uint256 preUpgradeUnitId,
        uint256 upgradeItemId
    ) external onlyOwner {
        uint256 unitId = nextUnitId;
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
