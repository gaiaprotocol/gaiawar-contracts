// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./OperatorManagement.sol";
import "./IBattleground.sol";
import "./ILootVault.sol";
import "../data/IBuildingManager.sol";

contract Battleground is OperatorManagement, IBattleground {
    uint16 public override width;
    uint16 public override height;
    uint16 public maxUnitsPerTile;

    ILootVault public lootVault;
    IBuildingManager public buildingManager;

    mapping(int16 => mapping(int16 => Tile)) public tiles;
    mapping(address => Coordinates[]) public playerHeadquarters;

    event TileUpdated(Coordinates coordinates, Tile tile);

    function initialize(
        uint16 _width,
        uint16 _height,
        uint16 _maxUnitsPerTile,
        address _lootVault,
        address _buildingManager
    ) external initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;
        maxUnitsPerTile = _maxUnitsPerTile;

        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function updateDimensions(uint16 _width, uint16 _height) external onlyOwner {
        require(_width > 0, "Width must be greater than 0");
        require(_height > 0, "Height must be greater than 0");

        width = _width;
        height = _height;
    }

    function updateMaxUnitsPerTile(uint16 _maxUnitsPerTile) external onlyOwner {
        require(_maxUnitsPerTile > 0, "Max units per tile must be greater than 0");

        maxUnitsPerTile = _maxUnitsPerTile;
    }

    function updateLootVault(address _lootVault) external onlyOwner {
        lootVault = ILootVault(_lootVault);
    }

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }

    function getTile(Coordinates memory coordinates) external view returns (Tile memory) {
        return tiles[coordinates.x][coordinates.y];
    }

    function getTiles(Coordinates[] memory coordinates) external view returns (Tile[] memory) {
        uint256 count = coordinates.length;

        Tile[] memory result = new Tile[](count);
        for (uint256 i = 0; i < count; i++) {
            Coordinates memory coordinate = coordinates[i];
            result[i] = tiles[coordinate.x][coordinate.y];
        }

        return result;
    }

    function hasHeadquarters(address player) external view returns (bool) {
        return playerHeadquarters[player].length > 0;
    }

    modifier validCoordinates(Coordinates memory coordinates) {
        int16 minX = -int16(width / 2);
        int16 maxX = int16(width / 2 - 1);
        int16 minY = -int16(height / 2);
        int16 maxY = int16(height / 2 - 1);
        require(coordinates.x >= minX && coordinates.x <= maxX, "Invalid x coordinate");
        require(coordinates.y >= minY && coordinates.y <= maxY, "Invalid y coordinate");
        _;
    }

    function _addHQCoordinate(address player, Coordinates memory coordinates) private {
        playerHeadquarters[player].push(coordinates);
    }

    function _removeHQCoordinate(address player, Coordinates memory coordinates) private {
        Coordinates[] storage playerHQs = playerHeadquarters[player];
        uint256 length = playerHQs.length;

        for (uint256 i = 0; i < length; i++) {
            if (playerHQs[i].x == coordinates.x && playerHQs[i].y == coordinates.y) {
                playerHQs[i] = playerHQs[length - 1];
                playerHQs.pop();
                break;
            }
        }
    }

    function updateTile(
        Coordinates memory coordinates,
        Tile memory tile
    ) external override onlyOperator validCoordinates(coordinates) {
        uint16 totalUnits = 0;
        for (uint256 i = 0; i < tile.units.length; i++) {
            totalUnits += tile.units[i].quantity;
        }
        require(totalUnits <= maxUnitsPerTile, "Too many units on tile");

        Tile memory existingTile = tiles[coordinates.x][coordinates.y];
        IBuildingManager.Building memory existingBuilding = buildingManager.getBuilding(existingTile.buildingId);

        tiles[coordinates.x][coordinates.y] = tile;
        IBuildingManager.Building memory building = buildingManager.getBuilding(tile.buildingId);

        if (existingTile.occupant != address(0) && existingBuilding.isHeadquarters) {
            if (existingTile.occupant != tile.occupant || !building.isHeadquarters) {
                _removeHQCoordinate(existingTile.occupant, coordinates);
            }
            if (existingTile.occupant != tile.occupant && building.isHeadquarters) {
                _addHQCoordinate(tile.occupant, coordinates);
            }
        } else if (building.isHeadquarters) {
            _addHQCoordinate(tile.occupant, coordinates);
        }

        emit TileUpdated(coordinates, tile);
    }

    function collectLoot(Coordinates memory coordinates) external {
        Tile storage tile = tiles[coordinates.x][coordinates.y];
        require(tile.occupant == msg.sender, "You do not own this tile");

        lootVault.transferLoot(msg.sender, tile.loot);
        tile.loot = new TokenAmountLib.TokenAmount[](0);
    }
}
