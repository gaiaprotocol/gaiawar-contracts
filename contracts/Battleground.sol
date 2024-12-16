// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./entities/IBuildings.sol";

contract Battleground is OwnableUpgradeable {
    IBuildings public buildingsContract;
    address public constructionContract;

    struct Coordinates {
        int16 x;
        int16 y;
    }

    struct Tile {
        address owner;
        uint16 buildingId;
    }

    int16 public minTileX;
    int16 public minTileY;
    int16 public maxTileX;
    int16 public maxTileY;

    mapping(int16 => mapping(int16 => Tile)) public tiles;
    mapping(address => Coordinates[]) public userHeadquarters;

    event BuildingsContractSet(address buildingsContract);
    event ConstructionContractSet(address constructionContract);
    event BuildingPlaced(int16 x, int16 y, address indexed owner, uint16 buildingId);

    function getTile(int16 x, int16 y) external view returns (Tile memory) {
        return tiles[x][y];
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

    function hasHeadquarters(address user) external view returns (bool) {
        return userHeadquarters[user].length > 0;
    }

    function initialize(int16 _minTileX, int16 _minTileY, int16 _maxTileX, int16 _maxTileY) public initializer {
        __Ownable_init(msg.sender);

        minTileX = _minTileX;
        minTileY = _minTileY;
        maxTileX = _maxTileX;
        maxTileY = _maxTileY;
    }

    function setBuildingsContract(address _buildingsContract) external onlyOwner {
        buildingsContract = IBuildings(_buildingsContract);

        emit BuildingsContractSet(_buildingsContract);
    }

    function setConstructionContract(address _constructionContract) external onlyOwner {
        constructionContract = _constructionContract;

        emit ConstructionContractSet(_constructionContract);
    }

    modifier onlyConstructionContract() {
        require(msg.sender == constructionContract, "Only construction contract can call this function");
        _;
    }

    function _withinBounds(int16 x, int16 y) private view returns (bool) {
        return (x >= minTileX && x <= maxTileX && y >= minTileY && y <= maxTileY);
    }

    function _addHQCoordinate(address user, int16 x, int16 y) private {
        userHeadquarters[user].push(Coordinates(x, y));
    }

    function _removeHQCoordinate(address user, int16 x, int16 y) private {
        Coordinates[] storage userHQs = userHeadquarters[user];
        uint256 length = userHQs.length;

        for (uint256 i = 0; i < length; i++) {
            if (userHQs[i].x == x && userHQs[i].y == y) {
                userHQs[i] = userHQs[length - 1];
                userHQs.pop();
                break;
            }
        }
    }

    function placeBuilding(int16 x, int16 y, address newOwner, uint16 buildingId) external onlyConstructionContract {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile memory existingTile = tiles[x][y];

        require(
            existingTile.owner == address(0) || existingTile.owner == newOwner,
            "Tile already occupied by another user"
        );

        if (existingTile.owner != address(0) && buildingsContract.isHeadquarters(existingTile.buildingId)) {
            _removeHQCoordinate(existingTile.owner, x, y);
        }

        tiles[x][y] = Tile(newOwner, buildingId);

        if (buildingsContract.isHeadquarters(buildingId)) {
            _addHQCoordinate(newOwner, x, y);
        }

        emit BuildingPlaced(x, y, newOwner, buildingId);
    }

    function removeBuilding(int16 x, int16 y) external onlyConstructionContract {
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile memory existingTile = tiles[x][y];
        require(existingTile.owner != address(0), "No building on this tile");

        if (buildingsContract.isHeadquarters(existingTile.buildingId)) {
            _removeHQCoordinate(existingTile.owner, x, y);
        }

        delete tiles[x][y];

        emit BuildingPlaced(x, y, address(0), 0);
    }
}
