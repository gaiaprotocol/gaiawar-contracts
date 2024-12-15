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
        address occupant;
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
    event BuildingPlaced(int16 x, int16 y, address indexed occupant, uint16 buildingId);

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

    function placeBuilding(int16 x, int16 y, address occupant, uint16 buildingId) external onlyConstructionContract {
        require(x >= minTileX && x <= maxTileX, "X coordinate out of bounds");
        require(y >= minTileY && y <= maxTileY, "Y coordinate out of bounds");
        require(tiles[x][y].occupant == address(0), "Tile already occupied");

        tiles[x][y] = Tile(occupant, buildingId);

        if (buildingsContract.isHeadquarters(buildingId)) {
            userHeadquarters[occupant].push(Coordinates(x, y));
        }

        emit BuildingPlaced(x, y, occupant, buildingId);
    }

    function removeBuilding(int16 x, int16 y) external onlyConstructionContract {
        require(x >= minTileX && x <= maxTileX, "X coordinate out of bounds");
        require(y >= minTileY && y <= maxTileY, "Y coordinate out of bounds");

        Tile memory tile = tiles[x][y];
        require(tile.occupant != address(0), "No building on this tile");

        if (buildingsContract.isHeadquarters(tile.buildingId)) {
            Coordinates[] storage userHQs = userHeadquarters[tile.occupant];
            for (uint256 i = 0; i < userHQs.length; i++) {
                if (userHQs[i].x == x && userHQs[i].y == y) {
                    userHQs[i] = userHQs[userHQs.length - 1];
                    userHQs.pop();
                    break;
                }
            }
        }

        delete tiles[x][y];

        emit BuildingPlaced(x, y, address(0), 0);
    }
}
