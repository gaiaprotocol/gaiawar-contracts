// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBuildings.sol";

contract Buildings is OwnableUpgradeable, IBuildings {
    uint16 public nextBuildingId;
    mapping(uint16 => Building) public buildings;

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function addBuilding(Building calldata building) external onlyOwner {
        require(building.prerequisiteBuildingId < nextBuildingId, "Previous building does not exist");
        require(building.constructionCost.length > 0, "Construction cost must be provided");

        uint16 buildingId = nextBuildingId;
        nextBuildingId += 1;

        buildings[buildingId] = building;
    }

    function setConstructability(uint16 buildingId, bool canBeConstructed) external onlyOwner {
        require(buildingId < nextBuildingId, "Building does not exist");

        buildings[buildingId].canBeConstructed = canBeConstructed;
    }

    function getBuilding(uint16 buildingId) external view override returns (Building memory) {
        return buildings[buildingId];
    }
}
