// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./UnitCommand.sol";
import "../../data/IUnitManager.sol";
import "../../data/IBuildingManager.sol";

abstract contract AttackCommand is UnitCommand {
    using TokenAmountLib for TokenAmountLib.TokenAmount[];

    IBuildingManager public buildingManager;

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }

    function getHealthBoostPercentage(
        uint16 buildingId,
        UnitQuantityLib.UnitQuantity[] memory units
    ) internal view returns (uint256 healthBoostPercentage) {
        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        healthBoostPercentage = building.healthBoostPercentage;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            if (unit.healthBoostPercentage > 0) {
                healthBoostPercentage += unit.healthBoostPercentage * units[i].quantity;
            }
        }
    }

    function getDamageBoostPercentage(
        uint16 buildingId,
        UnitQuantityLib.UnitQuantity[] memory units
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
        UnitQuantityLib.UnitQuantity[] memory units,
        uint256 damage,
        uint256 healthBoostPercentage
    )
        internal
        view
        returns (
            UnitQuantityLib.UnitQuantity[] memory remainingUnits,
            uint256 totalRemainingUnitCount,
            TokenAmountLib.TokenAmount[] memory loot
        )
    {
        uint256 remainingUnitsLength = 0;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            uint256 unitHealthPoints = (uint256(unit.healthPoints) * (10000 + healthBoostPercentage)) / 10000;

            uint16 killedUnits = uint16(damage / unitHealthPoints);

            if (killedUnits == 0) {
                remainingUnitsLength++;
                continue;
            }

            if (killedUnits > units[i].quantity) {
                killedUnits = units[i].quantity;
            }

            units[i].quantity -= killedUnits;

            if (units[i].quantity > 0) {
                remainingUnitsLength++;
            }

            damage -= uint256(killedUnits) * unitHealthPoints;

            TokenAmountLib.TokenAmount[] memory trainingCost = unitManager.getTotalUnitTrainingCost(units[i].unitId);
            for (uint256 j = 0; j < trainingCost.length; j++) {
                trainingCost[j].amount *= killedUnits;
            }

            loot = loot.merge(trainingCost);
        }

        remainingUnits = new UnitQuantityLib.UnitQuantity[](remainingUnitsLength);

        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i].quantity > 0) {
                remainingUnits[index] = units[i];
                index++;

                totalRemainingUnitCount += units[i].quantity;
            }
        }
    }
}
