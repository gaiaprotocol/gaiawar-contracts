// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/UnitCommand.sol";

contract Train is UnitCommand {
    using CostOperations for CostOperations.Cost[];

    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }

    function train(
        IBattleground.Coordinates memory coordinates,
        IBattleground.UnitQuantity memory unitQuantity
    ) external {
        require(unitQuantity.quantity > 0, "Quantity must be greater than 0");

        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Not the tile owner");

        IUnitManager.Unit memory unit = unitManager.getUnit(unitQuantity.unitId);
        require(unit.canBeTrained, "Unit can't be trained");

        bool foundTrainingBuilding = false;
        for (uint256 i = 0; i < unit.trainingBuildingIds.length; i++) {
            if (tile.buildingId == unit.trainingBuildingIds[i]) {
                foundTrainingBuilding = true;
                break;
            }
        }

        require(foundTrainingBuilding, "Unit can't be trained");

        CostOperations.Cost[] memory cost = unit.trainingCost;
        require(cost.transferFrom(msg.sender, address(lootVault)), "Training cost transfer failed");

        bool foundUnit = false;

        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitQuantity.unitId) {
                tile.units[i].quantity += unitQuantity.quantity;
                foundUnit = true;
            }
        }

        if (!foundUnit) {
            IBattleground.UnitQuantity[] memory newUnits = new IBattleground.UnitQuantity[](tile.units.length + 1);
            for (uint256 i = 0; i < tile.units.length; i++) {
                newUnits[i] = tile.units[i];
            }
            newUnits[tile.units.length] = unitQuantity;
            tile.units = newUnits;
        }

        battleground.updateTile(coordinates, tile);
    }
}
