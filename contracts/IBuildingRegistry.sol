// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IBuildingRegistry {
    struct Building {
        uint16 preUpgradeBuildingId;
        uint8 level;
        uint16 assetVersion;
        uint256[] constructionCosts;
        bool isHeadquarters;
    }

    function getBuilding(uint16 buildingId) external view returns (Building memory);

    function canProduceUnit(uint16 buildingId, uint16 unitId) external view returns (bool);
}
