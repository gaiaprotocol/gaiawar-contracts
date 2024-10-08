// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract GaiaWar is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct UnitAmount {
        uint16 unitId;
        uint16 amount;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitAmount[] units;
    }

    mapping(uint16 => mapping(uint16 => Tile)) public map;

    uint16 public mapRows;
    uint16 public mapCols;

    uint16 public maxUnitsPerTile;
    uint16 public maxUnitMovementRange;

    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);
    event MaxUnitMovementRangeUpdated(uint16 newMaxRange);

    function initialize(
        uint16 _mapRows,
        uint16 _mapCols,
        uint16 _maxUnitsPerTile,
        uint16 _maxUnitMovementRange
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        mapRows = _mapRows;
        mapCols = _mapCols;
        maxUnitsPerTile = _maxUnitsPerTile;
        maxUnitMovementRange = _maxUnitMovementRange;

        emit MapSizeUpdated(_mapRows, _mapCols);
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
        emit MaxUnitMovementRangeUpdated(_maxUnitMovementRange);
    }

    function setMapSize(uint16 _newRows, uint16 _newCols) external onlyOwner {
        mapRows = _newRows;
        mapCols = _newCols;
        emit MapSizeUpdated(_newRows, _newCols);
    }

    function setMaxUnitsPerTile(uint16 _newMaxUnits) external onlyOwner {
        maxUnitsPerTile = _newMaxUnits;
        emit MaxUnitsPerTileUpdated(_newMaxUnits);
    }

    function setMaxUnitMovementRange(uint16 _newMaxRange) external onlyOwner {
        maxUnitMovementRange = _newMaxRange;
        emit MaxUnitMovementRangeUpdated(_newMaxRange);
    }

    event UnitsMoved(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol, UnitAmount[] units);

    function moveUnits(
        uint16 fromRow,
        uint16 fromCol,
        uint16 toRow,
        uint16 toCol,
        UnitAmount[] calldata unitsToMove
    ) external {
        require(fromRow < mapRows, "Invalid fromRow");
        require(fromCol < mapCols, "Invalid fromCol");
        require(toRow < mapRows, "Invalid toRow");
        require(toCol < mapCols, "Invalid toCol");

        Tile storage fromTile = map[fromRow][fromCol];
        Tile storage toTile = map[toRow][toCol];

        require(fromTile.occupant == msg.sender, "Not your unit");
        require(toTile.occupant == msg.sender || toTile.occupant == address(0), "Not your tile");

        uint16 totalMovingUnits;
        for (uint256 i = 0; i < unitsToMove.length; i++) {
            totalMovingUnits += unitsToMove[i].amount;
        }
        require(totalMovingUnits <= maxUnitsPerTile, "Exceeds max units per tile");

        for (uint256 i = 0; i < unitsToMove.length; i++) {
            bool foundInFrom = false;
            bool foundInTo = false;

            // Update units in the 'from' tile
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == unitsToMove[i].unitId) {
                    require(fromTile.units[j].amount >= unitsToMove[i].amount, "Not enough units");
                    fromTile.units[j].amount -= unitsToMove[i].amount;
                    foundInFrom = true;
                    break;
                }
            }
            require(foundInFrom, "Unit not found in source tile");

            // Update units in the 'to' tile
            for (uint256 j = 0; j < toTile.units.length; j++) {
                if (toTile.units[j].unitId == unitsToMove[i].unitId) {
                    toTile.units[j].amount += unitsToMove[i].amount;
                    foundInTo = true;
                    break;
                }
            }

            // If the unit type doesn't exist in the 'to' tile, add it
            if (!foundInTo) {
                toTile.units.push(UnitAmount(unitsToMove[i].unitId, unitsToMove[i].amount));
            }
        }

        // Update occupant of 'to' tile if it was empty
        if (toTile.occupant == address(0)) {
            toTile.occupant = msg.sender;
        }

        emit UnitsMoved(fromRow, fromCol, toRow, toCol, unitsToMove);
    }

    function attack(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol) external {}
}
