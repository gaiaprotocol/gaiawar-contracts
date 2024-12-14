// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./entities/IBuildings.sol";

contract Battleground is OwnableUpgradeable {
    IBuildings public buildingsContract;
    address public constructionContract;

    struct Coordinates {
        uint16 x;
        uint16 y;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
    }

    uint16 public width;
    uint16 public height;

    mapping(uint16 => mapping(uint16 => Tile)) public tiles;
    mapping(address => Coordinates[]) public userHeadquarters;

    event BuildingsContractSet(address buildingsContract);
    event ConstructionContractSet(address constructionContract);
    event BuildingPlaced(uint16 x, uint16 y, address indexed occupant, uint16 buildingId);

    function getTile(uint16 x, uint16 y) external view returns (Tile memory) {
        return tiles[x][y];
    }

    function getTileArea(
        uint16 startX,
        uint16 startY,
        uint16 endX,
        uint16 endY
    ) external view returns (Tile[][] memory) {
        require(startX <= endX && startX < width, "Invalid X start coordinate");
        require(startY <= endY && startY < height, "Invalid Y start coordinate");
        require(endX < width, "X end coordinate out of bounds");
        require(endY < height, "Y end coordinate out of bounds");

        uint16 areaWidth = endX - startX + 1;
        uint16 areaHeight = endY - startY + 1;

        Tile[][] memory area = new Tile[][](areaHeight);
        for (uint16 y = 0; y < areaHeight; y++) {
            area[y] = new Tile[](areaWidth);
            for (uint16 x = 0; x < areaWidth; x++) {
                area[y][x] = tiles[startX + x][startY + y];
            }
        }

        return area;
    }

    function hasHeadquarters(address user) external view returns (bool) {
        return userHeadquarters[user].length > 0;
    }

    function initialize(uint16 _width, uint16 _height) public initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;
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

    function placeBuilding(uint16 x, uint16 y, address occupant, uint16 buildingId) external onlyConstructionContract {
        require(x < width, "X coordinate out of bounds");
        require(y < height, "Y coordinate out of bounds");
        require(tiles[x][y].occupant == address(0), "Tile already occupied");

        tiles[x][y] = Tile(occupant, buildingId);

        if (buildingsContract.isHeadquarters(buildingId)) {
            userHeadquarters[occupant].push(Coordinates(x, y));
        }

        emit BuildingPlaced(x, y, occupant, buildingId);
    }

    function removeBuilding(uint16 x, uint16 y) external onlyConstructionContract {
        require(x < width, "X coordinate out of bounds");
        require(y < height, "Y coordinate out of bounds");

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
