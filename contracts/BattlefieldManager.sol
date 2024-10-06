// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract BattlefieldManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public buildingManager;
    address public unitManager;

    event BuildingManagerSet(address indexed newBuildingManager);
    event UnitManagerSet(address indexed newUnitManager);

    function setBuildingManager(address _newBuildingManager) external onlyOwner {
        buildingManager = _newBuildingManager;
        emit BuildingManagerSet(_newBuildingManager);
    }

    function setUnitManager(address _newUnitManager) external onlyOwner {
        unitManager = _newUnitManager;
        emit UnitManagerSet(_newUnitManager);
    }

    modifier onlyBuildingManager() {
        require(msg.sender == buildingManager, "Caller is not the BuildingManager");
        _;
    }

    modifier onlyUnitManager() {
        require(msg.sender == unitManager, "Caller is not the UnitManager");
        _;
    }

    uint16 public mapRows;
    uint16 public mapCols;
    uint16 public maxUnitsPerTile;

    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);

    function setMapSize(uint16 _newRows, uint16 _newCols) external onlyOwner {
        mapRows = _newRows;
        mapCols = _newCols;
        emit MapSizeUpdated(_newRows, _newCols);
    }

    function setMaxUnitsPerTile(uint16 _newMaxUnits) external onlyOwner {
        maxUnitsPerTile = _newMaxUnits;
        emit MaxUnitsPerTileUpdated(_newMaxUnits);
    }

    function initialize(
        address _buildingManager,
        address _unitManager,
        uint16 _mapRows,
        uint16 _mapCols,
        uint16 _maxUnitsPerTile
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        buildingManager = _buildingManager;
        unitManager = _unitManager;
        mapRows = _mapRows;
        mapCols = _mapCols;
        maxUnitsPerTile = _maxUnitsPerTile;

        emit BuildingManagerSet(_buildingManager);
        emit UnitManagerSet(_unitManager);
        emit MapSizeUpdated(_mapRows, _mapCols);
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        uint16 buildingLevel;
        uint16 unitId;
        uint16 unitQuantity;
    }

    mapping(uint16 => mapping(uint16 => Tile)) public battlefield;

    event BuildingPlaced(uint16 row, uint16 col, uint16 buildingId, uint16 buildingLevel);
    event UnitPlaced(uint16 row, uint16 col, uint16 unitId, uint16 quantity);
    event UnitMoved(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol, uint16 unitId, uint16 quantity);

    function placeBuilding(
        uint16 row,
        uint16 col,
        address occupant,
        uint16 buildingId,
        uint16 buildingLevel
    ) external onlyBuildingManager nonReentrant {
        require(row >= 0 && row < mapRows && col >= 0 && col < mapCols, "Invalid coordinates");
        require(battlefield[row][col].occupant == address(0), "Tile is already occupied");

        battlefield[row][col] = Tile({
            occupant: occupant,
            buildingId: buildingId,
            buildingLevel: buildingLevel,
            unitId: 0,
            unitQuantity: 0
        });

        emit BuildingPlaced(row, col, buildingId, buildingLevel);
    }

    function placeUnits(
        uint16 row,
        uint16 col,
        address occupant,
        uint16 unitId,
        uint16 quantity
    ) external onlyUnitManager nonReentrant {
        require(row >= 0 && row < mapRows && col >= 0 && col < mapCols, "Invalid coordinates");
        require(battlefield[row][col].occupant == occupant, "Tile is not owned by the occupant");
        require(battlefield[row][col].unitQuantity + quantity <= maxUnitsPerTile, "Exceeds max units per tile");

        Tile storage tile = battlefield[row][col];

        if (tile.unitId == unitId) {
            tile.unitQuantity += quantity;
        } else if (tile.unitQuantity == 0) {
            tile.unitId = unitId;
            tile.unitQuantity = quantity;
        } else {
            revert("Cannot mix different unit types on the same tile");
        }

        emit UnitPlaced(row, col, unitId, quantity);
    }

    function moveUnits(
        uint16 fromRow,
        uint16 fromCol,
        uint16 toRow,
        uint16 toCol,
        uint16 quantity
    ) external onlyUnitManager nonReentrant {
        require(fromRow >= 0 && fromRow < mapRows && fromCol >= 0 && fromCol < mapCols, "Invalid source coordinates");
        require(toRow >= 0 && toRow < mapRows && toCol >= 0 && toCol < mapCols, "Invalid destination coordinates");

        Tile storage sourceTile = battlefield[fromRow][fromCol];
        Tile storage destTile = battlefield[toRow][toCol];

        require(sourceTile.unitQuantity >= quantity, "Not enough units to move");
        require(destTile.occupant == sourceTile.occupant, "Destination tile is not owned by the same occupant");
        require(destTile.unitQuantity + quantity <= maxUnitsPerTile, "Exceeds max units per tile at destination");

        uint16 unitId = sourceTile.unitId;

        // Remove units from source tile
        sourceTile.unitQuantity -= quantity;
        if (sourceTile.unitQuantity == 0) {
            sourceTile.unitId = 0;
        }

        // Add units to destination tile
        if (destTile.unitId == unitId || destTile.unitQuantity == 0) {
            destTile.unitId = unitId;
            destTile.unitQuantity += quantity;
        } else {
            revert("Cannot mix different unit types on the same tile");
        }

        emit UnitMoved(fromRow, fromCol, toRow, toCol, unitId, quantity);
    }
}
