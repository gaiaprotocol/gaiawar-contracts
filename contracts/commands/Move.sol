// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/UnitCommand.sol";
import "../libraries/CoordinatesOperations.sol";

contract Move is UnitCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using UnitQuantityOperations for UnitQuantityOperations.UnitQuantity[];

    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }

    function move(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityOperations.UnitQuantity[] memory units
    ) external onlyOwner {
        require(units.length > 0, "No units to move");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are moving from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(toTile.occupant == address(0) || toTile.occupant == msg.sender, "You cannot move to an occupied tile");

        uint16 distance = from.manhattanDistance(to);

        for (uint256 i = 0; i < units.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == units[i].unitId) {
                    require(fromTile.units[j].quantity >= units[i].quantity, "Not enough units to move");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            require(distance <= unit.movementRange, "Unit cannot move that far");
        }

        fromTile.units = fromTile.units.subtract(units);
        if (fromTile.units.length == 0) {
            fromTile.occupant = address(0);
        }
        battleground.updateTile(from, fromTile);

        toTile.units = toTile.units.merge(units);
        toTile.occupant = msg.sender;
        battleground.updateTile(to, toTile);
    }
}
