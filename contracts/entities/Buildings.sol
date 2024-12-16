// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBuildings.sol";

contract Buildings is OwnableUpgradeable, IBuildings {
    struct Building {
        uint16 previousBuildingId;
        ConstructionCost[] constructionCosts;
        bool isHeadquarters;
        uint16 constructionRange;
        bool canBeConstructed;
    }

    uint16 public nextBuildingId;
    mapping(uint16 => Building) public buildings;

    function getParentBuildingId(uint16 buildingId) external view returns (uint16) {
        return buildings[buildingId].previousBuildingId;
    }

    function getConstructionCosts(uint16 buildingId) external view returns (ConstructionCost[] memory) {
        return buildings[buildingId].constructionCosts;
    }

    function isHeadquarters(uint16 buildingId) external view returns (bool) {
        return buildings[buildingId].isHeadquarters;
    }

    function getConstructionRange(uint16 buildingId) external view returns (uint16) {
        return buildings[buildingId].constructionRange;
    }

    function canBeConstructed(uint16 buildingId) external view returns (bool) {
        return buildings[buildingId].canBeConstructed;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function addBuilding(
        uint16 previousBuildingId,
        ConstructionCost[] calldata constructionCosts,
        bool isHeadquarters,
        uint16 constructionRange,
        bool canBeConstructed
    ) external onlyOwner {
        require(previousBuildingId < nextBuildingId, "Previous building does not exist");
        require(constructionCosts.length > 0, "Construction costs must be provided");

        uint16 buildingId = nextBuildingId;
        nextBuildingId += 1;

        buildings[buildingId] = Building({
            previousBuildingId: previousBuildingId,
            constructionCosts: constructionCosts,
            isHeadquarters: isHeadquarters,
            constructionRange: constructionRange,
            canBeConstructed: canBeConstructed
        });
    }

    function setConstructability(uint16 buildingId, bool canBeConstructed) external onlyOwner {
        require(buildingId < nextBuildingId, "Building does not exist");

        buildings[buildingId].canBeConstructed = canBeConstructed;
    }
}
