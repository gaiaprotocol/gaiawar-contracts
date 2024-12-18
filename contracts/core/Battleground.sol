// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./OperatorManagement.sol";
import "./ILootVault.sol";

contract Battleground is OperatorManagement {
    struct Coordinates {
        int16 x;
        int16 y;
    }

    uint16 public width;
    uint16 public height;

    event DimensionsUpdated(uint16 width, uint16 height);

    struct UnitQuantity {
        uint16 unitId;
        uint16 quantity;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitQuantity[] units;
        ILootVault.Loot[] loot;
    }

    function initialize(uint16 _width, uint16 _height) public initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;

        emit DimensionsUpdated(_width, _height);
    }

    function setDimensions(uint16 _width, uint16 _height) external onlyOwner {
        require(_width > 0, "Width must be greater than 0");
        require(_height > 0, "Height must be greater than 0");

        width = _width;
        height = _height;

        emit DimensionsUpdated(_width, _height);
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
}
