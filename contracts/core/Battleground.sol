// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./OperatorManagement.sol";
import "./IBattleground.sol";

contract Battleground is OperatorManagement, IBattleground {
    uint16 public width;
    uint16 public height;
    uint16 public maxUnitsPerTile;

    event DimensionsUpdated(uint16 width, uint16 height);
    event MaxUnitsPerTileUpdated(uint16 maxUnitsPerTile);

    mapping(int16 => mapping(int16 => Tile)) public tiles;

    event TileUpdated(Coordinates coordinates, Tile tile);

    function initialize(uint16 _width, uint16 _height) public initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;

        emit DimensionsUpdated(_width, _height);
    }

    function updateDimensions(uint16 _width, uint16 _height) external onlyOwner {
        require(_width > 0, "Width must be greater than 0");
        require(_height > 0, "Height must be greater than 0");

        width = _width;
        height = _height;

        emit DimensionsUpdated(_width, _height);
    }

    function updateMaxUnitsPerTile(uint16 _maxUnitsPerTile) external onlyOwner {
        require(_maxUnitsPerTile > 0, "Max units per tile must be greater than 0");

        maxUnitsPerTile = _maxUnitsPerTile;
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
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

    function updateTile(
        Coordinates memory coordinates,
        Tile memory tile
    ) external override onlyOperator validCoordinates(coordinates) {
        uint16 totalUnits = 0;
        for (uint256 i = 0; i < tile.units.length; i++) {
            totalUnits += tile.units[i].quantity;
        }
        require(totalUnits <= maxUnitsPerTile, "Too many units on tile");

        tiles[coordinates.x][coordinates.y] = tile;
        emit TileUpdated(coordinates, tile);
    }
}
