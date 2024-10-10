// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MapStorage is OwnableUpgradeable {
    struct UnitAmount {
        uint16 unitId;
        uint16 amount;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitAmount[] units;
    }

    uint16 public mapRows;
    uint16 public mapCols;
    uint16 public maxUnitsPerTile;

    mapping(uint16 => mapping(uint16 => Tile)) public map;
    mapping(address => bool) public whitelist;

    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);
    event TileUpdated(uint16 row, uint16 col, address occupant, uint16 buildingId, UnitAmount[] units);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    function initialize(uint16 _mapRows, uint16 _mapCols, uint16 _maxUnitsPerTile) public initializer {
        __Ownable_init(msg.sender);

        mapRows = _mapRows;
        mapCols = _mapCols;
        maxUnitsPerTile = _maxUnitsPerTile;

        emit MapSizeUpdated(_mapRows, _mapCols);
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
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

    function addToWhitelist(address _address) external onlyOwner {
        require(!whitelist[_address], "Address is already whitelisted");
        whitelist[_address] = true;
        emit WhitelistAdded(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        require(whitelist[_address], "Address is not whitelisted");
        whitelist[_address] = false;
        emit WhitelistRemoved(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }

    function updateTile(
        uint16 row,
        uint16 col,
        address occupant,
        uint16 buildingId,
        UnitAmount[] memory units
    ) external onlyWhitelisted {
        require(row < mapRows && col < mapCols, "Invalid coordinates");

        uint16 totalUnits = 0;
        for (uint256 i = 0; i < units.length; i++) {
            totalUnits += units[i].amount;
        }
        require(totalUnits <= maxUnitsPerTile, "Exceeds max units per tile");

        map[row][col] = Tile(occupant, buildingId, units);
        emit TileUpdated(row, col, occupant, buildingId, units);
    }
}
