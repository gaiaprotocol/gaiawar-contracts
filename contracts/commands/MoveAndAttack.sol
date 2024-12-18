// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/AttackCommand.sol";
import "../libraries/CoordinatesOperations.sol";

contract MoveAndAttack is AttackCommand {
    using CoordinatesOperations for IBattleground.Coordinates;

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

    function moveAndAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        IBattleground.UnitQuantity[] memory attackerUnits
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
    }
}
