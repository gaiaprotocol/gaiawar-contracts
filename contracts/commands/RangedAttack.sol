// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./base/AttackCommand.sol";
import "../libraries/CoordinatesLib.sol";

contract RangedAttack is AttackCommand, ReentrancyGuardUpgradeable {
    using CoordinatesLib for IBattleground.Coordinates;
    using TokenAmountLib for TokenAmountLib.TokenAmount[];

    function initialize(
        address _lootVault,
        address _buildingManager,
        address _unitManager,
        address _battleground,
        address _clanEmblems
    ) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
        unitManager = IUnitManager(_unitManager);
        battleground = IBattleground(_battleground);
        clanEmblems = ClanEmblems(_clanEmblems);
    }

    function rangedAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityLib.UnitQuantity[] memory attackerUnits
    ) external nonReentrant {
        require(attackerUnits.length > 0, "No units to attack with");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are attacking from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(
            toTile.occupant != address(0) && toTile.occupant != msg.sender,
            "You cannot attack an empty tile or your own tile"
        );
        require(!battleground.isNewPlayer(toTile.occupant), "You cannot attack a new player");
        require(
            !clanEmblems.sharesAnyClan(msg.sender, toTile.occupant),
            "You cannot attack a tile owned by a clan member"
        );

        uint16 distance = from.manhattanDistance(to);

        uint256 attackerDamage = 0;
        TokenAmountLib.TokenAmount[] memory totalAttackCost;

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

            TokenAmountLib.TokenAmount[] memory attackCost = unit.rangedAttackCost;
            for (uint256 k = 0; k < attackCost.length; k++) {
                attackCost[k].amount *= attackerUnits[i].quantity;
            }

            totalAttackCost = totalAttackCost.merge(attackCost);
        }

        totalAttackCost.transferAll(msg.sender, address(lootVault));

        (
            UnitQuantityLib.UnitQuantity[] memory remainingUnits,
            ,
            TokenAmountLib.TokenAmount[] memory defenderLoot
        ) = applyDamageToUnits(
                toTile.units,
                (attackerDamage * (10000 + getDamageBoostPercentage(fromTile.buildingId, attackerUnits))) / 10000,
                getHealthBoostPercentage(toTile.buildingId, toTile.units)
            );

        if (remainingUnits.length == 0) {
            toTile.occupant = address(0);
            toTile.units = new UnitQuantityLib.UnitQuantity[](0);

            if (toTile.buildingId == 0) {
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
            } else {
                TokenAmountLib.TokenAmount[] memory constructionCost = buildingManager.getTotalBuildingConstructionCost(
                    toTile.buildingId
                );
                toTile.buildingId = 0;
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost).merge(constructionCost);
            }
        } else {
            toTile.units = remainingUnits;
            toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
        }

        battleground.updateTile(to, toTile);
    }
}
