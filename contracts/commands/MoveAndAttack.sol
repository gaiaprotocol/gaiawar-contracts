// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/AttackCommand.sol";
import "../libraries/CoordinatesLib.sol";

contract MoveAndAttack is AttackCommand {
    using CoordinatesLib for IBattleground.Coordinates;
    using UnitQuantityLib for UnitQuantityLib.UnitQuantity[];
    using TokenAmountLib for TokenAmountLib.TokenAmount[];

    function initialize(
        address _lootVault,
        address _buildingManager,
        address _unitManager,
        address _battleground,
        address _clanEmblems
    ) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
        unitManager = IUnitManager(_unitManager);
        battleground = IBattleground(_battleground);
        clanEmblems = ClanEmblems(_clanEmblems);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function moveAndAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityLib.UnitQuantity[] memory attackerUnits
    ) external {
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
            require(distance <= unit.movementRange, "Unit cannot move that far");
        }

        fromTile.units = fromTile.units.subtract(attackerUnits);
        if (fromTile.buildingId == 0 && fromTile.units.length == 0) {
            fromTile.occupant = address(0);
        }
        battleground.updateTile(from, fromTile);

        UnitQuantityLib.UnitQuantity[] memory defenderUnits = toTile.units;
        TokenAmountLib.TokenAmount[] memory totalLoot = toTile.loot;

        bool toFinish = false;
        while (true) {
            uint256 attackerDamage = toFinish ? type(uint256).max : 0;
            uint256 totalAttackerUnitCount;

            if (toFinish) {
                for (uint256 i = 0; i < attackerUnits.length; i++) {
                    totalAttackerUnitCount += attackerUnits[i].quantity;
                }
            } else {
                for (uint256 i = 0; i < attackerUnits.length; i++) {
                    IUnitManager.Unit memory unit = unitManager.getUnit(attackerUnits[i].unitId);
                    attackerDamage += uint256(unit.attackDamage) * uint256(attackerUnits[i].quantity);
                    totalAttackerUnitCount += attackerUnits[i].quantity;
                }
                attackerDamage = (attackerDamage * (10000 + getDamageBoostPercentage(0, attackerUnits))) / 10000;
            }

            uint256 defenderDamage = toFinish ? type(uint256).max : 0;
            uint256 totalDefenderUnitCount;

            if (toFinish) {
                for (uint256 i = 0; i < defenderUnits.length; i++) {
                    totalDefenderUnitCount += defenderUnits[i].quantity;
                }
            } else {
                for (uint256 i = 0; i < defenderUnits.length; i++) {
                    IUnitManager.Unit memory unit = unitManager.getUnit(defenderUnits[i].unitId);
                    defenderDamage += uint256(unit.attackDamage) * uint256(defenderUnits[i].quantity);
                    totalDefenderUnitCount += defenderUnits[i].quantity;
                }
                defenderDamage =
                    (defenderDamage * (10000 + getDamageBoostPercentage(toTile.buildingId, defenderUnits))) /
                    10000;
            }

            (
                UnitQuantityLib.UnitQuantity[] memory remainingDefenderUnits,
                uint256 totalRemainingDefenderUnitCount,
                TokenAmountLib.TokenAmount[] memory attackerLoot
            ) = applyDamageToUnits(
                    defenderUnits,
                    attackerDamage,
                    getHealthBoostPercentage(toTile.buildingId, defenderUnits)
                );

            (
                UnitQuantityLib.UnitQuantity[] memory remainingAttackerUnits,
                uint256 totalRemainingAttackerUnitCount,
                TokenAmountLib.TokenAmount[] memory defenderLoot
            ) = applyDamageToUnits(attackerUnits, defenderDamage, getHealthBoostPercentage(0, attackerUnits));

            totalLoot = totalLoot.merge(attackerLoot).merge(defenderLoot);

            // Attacker wins
            if (remainingAttackerUnits.length > 0 && remainingDefenderUnits.length == 0) {
                toTile.occupant = msg.sender;
                toTile.units = remainingAttackerUnits;

                if (toTile.buildingId == 0) {
                    if (totalLoot.length > 0) {
                        lootVault.transferLoot(msg.sender, totalLoot);
                    }
                } else {
                    TokenAmountLib.TokenAmount[] memory constructionCost = buildingManager
                        .getTotalBuildingConstructionCost(toTile.buildingId);
                    toTile.buildingId = 0;
                    totalLoot = totalLoot.merge(constructionCost);
                    if (totalLoot.length > 0) {
                        lootVault.transferLoot(msg.sender, totalLoot);
                    }
                }

                toTile.loot = new TokenAmountLib.TokenAmount[](0);

                battleground.updateTile(to, toTile);
                break;
            }
            // Defender wins
            else if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length > 0) {
                toTile.units = remainingDefenderUnits;
                toTile.loot = totalLoot;

                battleground.updateTile(to, toTile);
                break;
            }
            // Draw
            else if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length == 0) {
                toTile.occupant = address(0);
                toTile.units = new UnitQuantityLib.UnitQuantity[](0);

                if (toTile.buildingId == 0) {
                    toTile.loot = totalLoot;
                } else {
                    TokenAmountLib.TokenAmount[] memory constructionCost = buildingManager
                        .getTotalBuildingConstructionCost(toTile.buildingId);
                    toTile.buildingId = 0;
                    toTile.loot = totalLoot.merge(constructionCost);
                }

                battleground.updateTile(to, toTile);
                break;
            }
            // Never reached
            else if (
                totalRemainingAttackerUnitCount == totalAttackerUnitCount &&
                totalRemainingDefenderUnitCount == totalDefenderUnitCount
            ) {
                require(!toFinish, "Infinite loop detected");
                toFinish = true;
            }
            // Continue
            else {
                attackerUnits = remainingAttackerUnits;
                defenderUnits = remainingDefenderUnits;
            }
        }
    }
}
