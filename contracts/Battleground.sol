// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Battleground is OwnableUpgradeable {
    address public constructionContract;

    struct Tile {
        address occupant;
        uint16 building;
    }

    uint16 public width;
    uint16 public height;

    mapping(uint256 => mapping(uint256 => Tile)) public tiles;

    event ConstructionContractSet(address constructionContract);
    event BuildingPlaced(uint256 x, uint256 y, address indexed occupant, uint16 building);

    function initialize(uint16 _width, uint16 _height) public initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;
    }

    function setConstructionContract(address _constructionContract) external onlyOwner {
        constructionContract = _constructionContract;

        emit ConstructionContractSet(_constructionContract);
    }

    modifier onlyConstructionContract() {
        require(msg.sender == constructionContract, "Only construction contract can call this function");
        _;
    }

    function placeBuilding(uint256 x, uint256 y, address occupant, uint16 building) external onlyConstructionContract {
        require(x < width, "X coordinate out of bounds");
        require(y < height, "Y coordinate out of bounds");

        tiles[x][y] = Tile(occupant, building);

        emit BuildingPlaced(x, y, occupant, building);
    }
}
