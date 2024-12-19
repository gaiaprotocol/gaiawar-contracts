// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./base/UnitCommand.sol";

contract Train is UnitCommand, ReentrancyGuardUpgradeable {
    using TokenAmountLib for TokenAmountLib.TokenAmount[];

    function initialize(address _lootVault, address _unitManager, address _battleground) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
        battleground = IBattleground(_battleground);
    }

    function train(
        IBattleground.Coordinates memory coordinates,
        UnitQuantityLib.UnitQuantity memory unitQuantity
    ) external nonReentrant {
        require(unitQuantity.quantity > 0, "Quantity must be greater than 0");

        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Not the tile owner");

        IUnitManager.Unit memory unit = unitManager.getUnit(unitQuantity.unitId);
        require(unit.canBeTrained && unit.prerequisiteUnitId == 0, "Unit can't be trained");

        bool foundTrainingBuilding = false;
        for (uint256 i = 0; i < unit.trainingBuildingIds.length; i++) {
            if (tile.buildingId == unit.trainingBuildingIds[i]) {
                foundTrainingBuilding = true;
                break;
            }
        }

        require(foundTrainingBuilding, "Unit can't be trained");

        TokenAmountLib.TokenAmount[] memory cost = unit.trainingCost;
        for (uint256 i = 0; i < unit.trainingCost.length; i++) {
            cost[i].amount *= unitQuantity.quantity;
        }
        cost.transferAll(msg.sender, address(lootVault));

        bool foundSameUnit = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitQuantity.unitId) {
                tile.units[i].quantity += unitQuantity.quantity;
                foundSameUnit = true;
            }
        }

        if (!foundSameUnit) {
            UnitQuantityLib.UnitQuantity[] memory newUnits = new UnitQuantityLib.UnitQuantity[](tile.units.length + 1);
            for (uint256 i = 0; i < tile.units.length; i++) {
                newUnits[i] = tile.units[i];
            }
            newUnits[tile.units.length] = unitQuantity;
            tile.units = newUnits;
        }

        battleground.updateTile(coordinates, tile);
    }
}
