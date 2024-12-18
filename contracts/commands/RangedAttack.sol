// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/AttackCommand.sol";
import "../libraries/CoordinatesOperations.sol";

contract RangedAttack is AttackCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(
        address _battleground,
        address _lootVault,
        address _unitManager,
        address _buildingManager
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function rangedAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityOperations.UnitQuantity[] memory attackerUnits
    ) external onlyOwner {
        require(attackerUnits.length > 0, "No units to attack with");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are attacking from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(
            toTile.occupant != address(0) && toTile.occupant != msg.sender,
            "You cannot attack an empty tile or your own tile"
        );

        uint16 distance = from.manhattanDistance(to);

        uint256 attackerDamage = 0;
        TokenAmountOperations.TokenAmount[] memory totalAttackCost;

        for (uint256 i = 0; i < attackerUnits.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == attackerUnits[i].unitId) {
                    require(fromTile.units[j].quantity >= attackerUnits[i].quantity, "Not enough units to attack with");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            IUnitManager.Unit memory unit = unitManager.getUnit(attackerUnits[i].unitId);
            require(unit.attackRange >= distance, "Unit cannot attack that far");

            attackerDamage += unit.attackDamage * attackerUnits[i].quantity;

            TokenAmountOperations.TokenAmount[] memory attackCost = unit.rangedAttackCost;
            for (uint256 k = 0; k < attackCost.length; k++) {
                attackCost[k].amount *= attackerUnits[i].quantity;
            }

            totalAttackCost = totalAttackCost.merge(attackCost);
        }

        totalAttackCost.transferAll(msg.sender, address(lootVault));

        (
            UnitQuantityOperations.UnitQuantity[] memory remainingUnits,
            ,
            TokenAmountOperations.TokenAmount[] memory defenderLoot
        ) = applyDamageToUnits(toTile.units, attackerDamage);

        if (remainingUnits.length == 0) {
            toTile.occupant = address(0);
            toTile.units = new UnitQuantityOperations.UnitQuantity[](0);

            if (toTile.buildingId == 0) {
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
            } else {
                toTile.buildingId = 0;
                TokenAmountOperations.TokenAmount[] memory constructionCost = buildingManager
                    .getTotalBuildingConstructionCost(toTile.buildingId);
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost).merge(constructionCost);
            }
        } else {
            toTile.units = remainingUnits;
            toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
        }

        battleground.updateTile(to, toTile);
    }
}
