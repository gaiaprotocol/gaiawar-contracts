// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IMapStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

contract MapStorage is IMapStorage, OwnableUpgradeable, ERC1155HolderUpgradeable {
    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitAmount[] units;
    }

    uint16 public override mapRows;
    uint16 public override mapCols;
    uint16 public maxUnitsPerTile;

    mapping(uint16 => mapping(uint16 => Tile)) public map;
    mapping(address => bool) public whitelist;

    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    event TileOccupantUpdated(uint16 row, uint16 col, address occupant);
    event TileBuildingUpdated(uint16 row, uint16 col, uint16 buildingId);
    event TileUnitsUpdated(uint16 row, uint16 col, UnitAmount[] units);

    function initialize(uint16 _mapRows, uint16 _mapCols, uint16 _maxUnitsPerTile) public initializer {
        __Ownable_init(msg.sender);
        __ERC1155Holder_init();

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

    function getTileOccupant(uint16 row, uint16 col) external view override returns (address) {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        return map[row][col].occupant;
    }

    function getTileBuildingId(uint16 row, uint16 col) external view override returns (uint16) {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        return map[row][col].buildingId;
    }

    function getTileUnits(uint16 row, uint16 col) external view override returns (UnitAmount[] memory) {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        return map[row][col].units;
    }

    function updateTileOccupant(uint16 row, uint16 col, address occupant) external override onlyWhitelisted {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        map[row][col].occupant = occupant;
        emit TileOccupantUpdated(row, col, occupant);
    }

    function updateTileBuildingId(uint16 row, uint16 col, uint16 buildingId) external override onlyWhitelisted {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        map[row][col].buildingId = buildingId;
        emit TileBuildingUpdated(row, col, buildingId);
    }

    function updateTileUnits(uint16 row, uint16 col, UnitAmount[] memory units) external override onlyWhitelisted {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        require(units.length <= maxUnitsPerTile, "Too many units");
        map[row][col].units = units;
        emit TileUnitsUpdated(row, col, units);
    }
}
