// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IBuildingRegistry.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BuildingRegistry is IBuildingRegistry, OwnableUpgradeable {
    mapping(uint16 => Building) private buildings;
    uint16 private nextBuildingId;

    mapping(uint16 => mapping(uint16 => bool)) private buildingToUnitProduction;

    event BuildingAdded(
        uint16 buildingId,
        uint16 assetVersion,
        uint16 preUpgradeBuildingId,
        uint256[] constructionCosts,
        bool isHeadquarters
    );

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function getBuilding(uint16 buildingId) external view override returns (Building memory) {
        return buildings[buildingId];
    }

    function addBuilding(
        uint16 preUpgradeBuildingId,
        uint16 assetVersion,
        uint256[] calldata constructionCosts,
        bool isHeadquarters
    ) external onlyOwner {
        uint16 buildingId = nextBuildingId;
        nextBuildingId += 1;

        require(buildings[buildingId].assetVersion == 0, "Building already exists");

        buildings[buildingId] = Building({
            preUpgradeBuildingId: preUpgradeBuildingId,
            level: preUpgradeBuildingId == 0 ? 1 : buildings[preUpgradeBuildingId].level + 1,
            assetVersion: assetVersion,
            constructionCosts: constructionCosts,
            isHeadquarters: isHeadquarters
        });

        emit BuildingAdded(buildingId, assetVersion, preUpgradeBuildingId, constructionCosts, isHeadquarters);
    }

    function addProducibleUnits(uint16 buildingId, uint16[] calldata unitIds) external onlyOwner {
        for (uint16 i = 0; i < unitIds.length; i++) {
            buildingToUnitProduction[buildingId][unitIds[i]] = true;
        }
    }

    function removeProducibleUnits(uint16 buildingId, uint16[] calldata unitIds) external onlyOwner {
        for (uint16 i = 0; i < unitIds.length; i++) {
            buildingToUnitProduction[buildingId][unitIds[i]] = false;
        }
    }

    function canProduceUnit(uint16 buildingId, uint16 unitId) external view override returns (bool) {
        return buildingToUnitProduction[buildingId][unitId];
    }
}
