// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IBuildingManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BuildingManager is IBuildingManager, OwnableUpgradeable {
    mapping(uint256 => Building) private buildings;
    uint256 private nextBuildingId;

    mapping(uint256 => mapping(uint256 => bool)) private buildingToUnitProduction;

    event BuildingAdded(
        uint256 buildingId,
        uint16 assetVersion,
        uint256 preUpgradeBuildingId,
        uint256[] constructionCosts,
        bool isHeadquarters
    );

    function initialize() public initializer {
        __Ownable_init();

        nextBuildingId = 1;
    }

    function getBuilding(uint256 buildingId) external view override returns (Building memory) {
        return buildings[buildingId];
    }

    function addBuilding(
        uint256 preUpgradeBuildingId,
        uint16 assetVersion,
        uint256[] calldata constructionCosts,
        bool isHeadquarters
    ) external onlyOwner {
        uint256 buildingId = nextBuildingId;
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

    function addProducibleUnits(uint256 buildingId, uint256[] calldata unitIds) external onlyOwner {
        for (uint256 i = 0; i < unitIds.length; i++) {
            buildingToUnitProduction[buildingId][unitIds[i]] = true;
        }
    }

    function removeProducibleUnits(uint256 buildingId, uint256[] calldata unitIds) external onlyOwner {
        for (uint256 i = 0; i < unitIds.length; i++) {
            buildingToUnitProduction[buildingId][unitIds[i]] = false;
        }
    }

    function canProduceUnit(uint256 buildingId, uint256 unitId) external view override returns (bool) {
        return buildingToUnitProduction[buildingId][unitId];
    }
}
