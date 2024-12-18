// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./UnitCommand.sol";
import "../../data/IUnitManager.sol";
import "../../data/IBuildingManager.sol";

abstract contract AttackCommand is UnitCommand {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    IBuildingManager public buildingManager;

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }

    function getDamageBoostPercentage(
        uint16 buildingId,
        UnitQuantityOperations.UnitQuantity[] memory units
    ) internal view returns (uint256 damageBoostPercentage) {
        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        damageBoostPercentage = building.damageBoostPercentage;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            if (unit.damageBoostPercentage > 0) {
                damageBoostPercentage += unit.damageBoostPercentage * units[i].quantity;
            }
        }
    }

    function applyDamageToUnits(
        UnitQuantityOperations.UnitQuantity[] memory units,
        uint256 damage
    )
        internal
        view
        returns (
            UnitQuantityOperations.UnitQuantity[] memory remainingUnits,
            uint256 remainingDamage,
            TokenAmountOperations.TokenAmount[] memory loot
        )
    {
        remainingDamage = damage;

        uint256 remainingUnitsLength = 0;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            uint16 killedUnits = uint16(remainingDamage / unit.healthPoints);

            if (killedUnits == 0) {
                continue;
            }

            if (killedUnits > units[i].quantity) {
                killedUnits = units[i].quantity;
            }

            units[i].quantity -= killedUnits;

            if (units[i].quantity > 0) {
                remainingUnitsLength++;
            }

            remainingDamage -= uint256(killedUnits) * uint256(unit.healthPoints);

            TokenAmountOperations.TokenAmount[] memory trainingCost = unitManager.getTotalUnitTrainingCost(
                units[i].unitId
            );
            for (uint256 j = 0; j < trainingCost.length; j++) {
                trainingCost[j].amount *= killedUnits;
            }

            loot = loot.merge(trainingCost);
        }

        remainingUnits = new UnitQuantityOperations.UnitQuantity[](remainingUnitsLength);

        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i].quantity > 0) {
                remainingUnits[index] = units[i];
                index++;
            }
        }
    }
}
