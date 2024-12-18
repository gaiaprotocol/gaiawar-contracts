// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Battleground.sol";
import "../entities/IUnits.sol";

contract Attack is OwnableUpgradeable {
    using TokenOperations for TokenOperations.TokenAmount[];

    Battleground public battleground;
    IUnits public unitsContract;

    function initialize(address _battleground, address _unitsContract) public initializer {
        __Ownable_init(msg.sender);

        battleground = Battleground(_battleground);
        unitsContract = IUnits(_unitsContract);
    }

    function setBattleground(address _battleground) external onlyOwner {
        battleground = Battleground(_battleground);
    }

    function _manhattanDistance(int16 x1, int16 y1, int16 x2, int16 y2) private pure returns (uint16) {
        uint16 dx = x1 < x2 ? uint16(x2 - x1) : uint16(x1 - x2);
        uint16 dy = y1 < y2 ? uint16(y2 - y1) : uint16(y1 - y2);
        return dx + dy;
    }

    function _applyDamageToUnits(
        Battleground.UnitQuantity[] memory units,
        uint256 damage
    )
        private
        view
        returns (
            Battleground.UnitQuantity[] memory remainingUnits,
            uint256 remainingDamage,
            TokenOperations.TokenAmount[] memory loot
        )
    {
        remainingDamage = damage;

        uint256 remainingUnitsLength = 0;

        TokenOperations.TokenAmount[][] memory tempLoot = new TokenOperations.TokenAmount[][](units.length);
        uint256 totalLootTypes = 0;

        for (uint256 i = 0; i < units.length; i++) {
            uint16 hp = unitsContract.getHealthPoints(units[i].unitId);
            uint16 killedUnits = uint16(remainingDamage / hp);

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
            remainingDamage -= uint256(killedUnits) * uint256(hp);

            TokenOperations.TokenAmount[] memory unitLoot = unitsContract.getTrainingCost(units[i].unitId);
            for (uint256 j = 0; j < unitLoot.length; j++) {
                unitLoot[j].amount *= killedUnits;
            }
            tempLoot[i] = unitLoot;
            totalLootTypes += unitLoot.length;
        }

        remainingUnits = new Battleground.UnitQuantity[](remainingUnitsLength);

        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i].quantity > 0) {
                remainingUnits[index] = units[i];
                index++;
            }
        }

        loot = new TokenOperations.TokenAmount[](totalLootTypes);
        uint256 lootIndex = 0;

        for (uint256 i = 0; i < units.length; i++) {
            if (tempLoot[i].length == 0) continue;

            for (uint256 j = 0; j < tempLoot[i].length; j++) {
                bool found = false;
                for (uint256 k = 0; k < lootIndex; k++) {
                    if (loot[k].token == tempLoot[i][j].token) {
                        loot[k].amount += tempLoot[i][j].amount;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    loot[lootIndex] = tempLoot[i][j];
                    lootIndex++;
                }
            }
        }

        assembly {
            mstore(loot, lootIndex)
        }
    }

    function moveAndAttack(
        int16 fromX,
        int16 fromY,
        int16 toX,
        int16 toY,
        Battleground.UnitQuantity[] memory units
    ) external {
        require(units.length > 0, "No units specified");

        Battleground.Tile memory fromTile = battleground.getTile(fromX, fromY);
        require(fromTile.owner == msg.sender, "Not the tile owner");

        Battleground.Tile memory toTile = battleground.getTile(toX, toY);
        require(toTile.owner != address(0) && toTile.owner != msg.sender, "Invalid target");

        uint16 distance = _manhattanDistance(fromX, fromY, toX, toY);

        for (uint256 i = 0; i < units.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == units[i].unitId) {
                    require(fromTile.units[j].quantity >= units[i].quantity, "Insufficient units");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            uint8 movementRange = unitsContract.getMovementRange(units[i].unitId);
            require(distance <= movementRange, "Movement range exceeded");
        }

        Battleground.UnitQuantity[] memory attackerUnits = units;
        Battleground.UnitQuantity[] memory defenderUnits = toTile.units;
        TokenOperations.TokenAmount[] memory totalLoot = toTile.uncollectedLoot;

        bool toFinish = false;
        while (true) {
            uint256 attackerDamage = toFinish ? type(uint256).max : 0;
            if (!toFinish) {
                for (uint256 i = 0; i < attackerUnits.length; i++) {
                    uint16 damage = unitsContract.getAttackDamage(attackerUnits[i].unitId);
                    attackerDamage += uint256(damage) * uint256(attackerUnits[i].quantity);
                }
            }

            uint256 defenderDamage = toFinish ? type(uint256).max : 0;
            if (!toFinish) {
                for (uint256 i = 0; i < defenderUnits.length; i++) {
                    uint16 damage = unitsContract.getAttackDamage(defenderUnits[i].unitId);
                    defenderDamage += uint256(damage) * uint256(defenderUnits[i].quantity);
                }
            }

            (
                Battleground.UnitQuantity[] memory remainingDefenderUnits,
                uint256 remainingAttackerDamage,
                TokenOperations.TokenAmount[] memory attackerLoot
            ) = _applyDamageToUnits(defenderUnits, attackerDamage);

            if (totalLoot.length == 0) {
                totalLoot = attackerLoot;
            } else {
                for (uint256 i = 0; i < attackerLoot.length; i++) {
                    bool tokenFound = false;
                    for (uint256 j = 0; j < totalLoot.length; j++) {
                        if (totalLoot[j].token == attackerLoot[i].token) {
                            totalLoot[j].amount += attackerLoot[i].amount;
                            tokenFound = true;
                            break;
                        }
                    }
                    if (!tokenFound) {
                        TokenOperations.TokenAmount[] memory newTotalLoot = new TokenOperations.TokenAmount[](
                            totalLoot.length + 1
                        );
                        for (uint256 j = 0; j < totalLoot.length; j++) {
                            newTotalLoot[j] = totalLoot[j];
                        }
                        newTotalLoot[totalLoot.length] = attackerLoot[i];
                        totalLoot = newTotalLoot;
                    }
                }
            }

            (
                Battleground.UnitQuantity[] memory remainingAttackerUnits,
                uint256 remainingDefenderDamage,
                TokenOperations.TokenAmount[] memory defenderLoot
            ) = _applyDamageToUnits(attackerUnits, defenderDamage);

            if (totalLoot.length == 0) {
                totalLoot = defenderLoot;
            } else {
                for (uint256 i = 0; i < defenderLoot.length; i++) {
                    bool tokenFound = false;
                    for (uint256 j = 0; j < totalLoot.length; j++) {
                        if (totalLoot[j].token == defenderLoot[i].token) {
                            totalLoot[j].amount += defenderLoot[i].amount;
                            tokenFound = true;
                            break;
                        }
                    }
                    if (!tokenFound) {
                        TokenOperations.TokenAmount[] memory newTotalLoot = new TokenOperations.TokenAmount[](
                            totalLoot.length + 1
                        );
                        for (uint256 j = 0; j < totalLoot.length; j++) {
                            newTotalLoot[j] = totalLoot[j];
                        }
                        newTotalLoot[totalLoot.length] = defenderLoot[i];
                        totalLoot = newTotalLoot;
                    }
                }
            }

            // Attacker win
            if (remainingAttackerUnits.length > 0 && remainingDefenderUnits.length == 0) {
                totalLoot.transferTokens(address(battleground), msg.sender);
                battleground.updateTile(
                    toX,
                    toY,
                    msg.sender,
                    remainingAttackerUnits,
                    new TokenOperations.TokenAmount[](0)
                );
                break;
            }

            // Defender win
            if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length > 0) {
                totalLoot.transferTokens(address(battleground), toTile.owner);
                battleground.updateTile(
                    toX,
                    toY,
                    toTile.owner,
                    remainingDefenderUnits,
                    new TokenOperations.TokenAmount[](0)
                );
                break;
            }

            // Draw
            if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length == 0) {
                battleground.updateTile(toX, toY, address(0), new Battleground.UnitQuantity[](0), totalLoot);
                break;
            }

            // Never reached
            if (attackerDamage == remainingDefenderDamage && defenderDamage == remainingAttackerDamage) {
                toFinish = true;
            }
        }
    }

    function rangedAttack(
        int16 fromX,
        int16 fromY,
        int16 toX,
        int16 toY,
        Battleground.UnitQuantity[] memory units
    ) external {
        require(units.length > 0, "No units specified");

        Battleground.Tile memory fromTile = battleground.getTile(fromX, fromY);
        require(fromTile.owner == msg.sender, "Not the tile owner");

        Battleground.Tile memory toTile = battleground.getTile(toX, toY);
        require(toTile.owner != address(0) && toTile.owner != msg.sender, "Invalid target");

        uint16 distance = _manhattanDistance(fromX, fromY, toX, toY);

        uint256 totalDamage = 0;
        TokenOperations.TokenAmount[] memory totalCost;

        for (uint256 i = 0; i < units.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == units[i].unitId) {
                    require(fromTile.units[j].quantity >= units[i].quantity, "Insufficient units");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            uint8 attackRange = unitsContract.getAttackRange(units[i].unitId);
            require(distance <= attackRange, "Target out of range");

            uint16 attackDamage = unitsContract.getAttackDamage(units[i].unitId);
            totalDamage += uint256(attackDamage) * uint256(units[i].quantity);

            TokenOperations.TokenAmount[] memory attackCost = unitsContract.getRangedAttackCost(units[i].unitId);
            for (uint256 k = 0; k < attackCost.length; k++) {
                attackCost[k].amount *= units[i].quantity;
            }

            if (totalCost.length == 0) {
                totalCost = attackCost;
            } else {
                for (uint256 k = 0; k < attackCost.length; k++) {
                    bool tokenFound = false;
                    for (uint256 l = 0; l < totalCost.length; l++) {
                        if (totalCost[l].token == attackCost[k].token) {
                            totalCost[l].amount += attackCost[k].amount;
                            tokenFound = true;
                            break;
                        }
                    }
                    if (!tokenFound) {
                        TokenOperations.TokenAmount[] memory newTotalCost = new TokenOperations.TokenAmount[](
                            totalCost.length + 1
                        );
                        for (uint256 l = 0; l < totalCost.length; l++) {
                            newTotalCost[l] = totalCost[l];
                        }
                        newTotalCost[totalCost.length] = attackCost[k];
                        totalCost = newTotalCost;
                    }
                }
            }
        }

        require(totalCost.transferTokens(msg.sender, address(battleground)), "Failed to transfer attack cost");

        (
            Battleground.UnitQuantity[] memory remainingUnits,
            ,
            TokenOperations.TokenAmount[] memory loot
        ) = _applyDamageToUnits(toTile.units, totalDamage);

        if (remainingUnits.length == 0) {
            battleground.updateTile(toX, toY, address(0), remainingUnits, loot);
        } else {
            battleground.updateTile(toX, toY, toTile.owner, remainingUnits, new TokenOperations.TokenAmount[](0));
            loot.transferTokens(address(battleground), toTile.owner);
        }
    }
}
