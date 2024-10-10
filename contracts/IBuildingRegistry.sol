// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IBuildingRegistry {
    struct Building {
        uint256 preUpgradeBuildingId;
        uint8 level;
        uint16 assetVersion;
        uint256[] constructionCosts;
        bool isHeadquarters;
    }

    function getBuilding(uint256 buildingId) external view returns (Building memory);
}
