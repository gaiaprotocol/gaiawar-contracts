// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBuildingManager {
    struct Building {
        uint16 assetVersion;
        uint256 preUpgradeBuildingId;
        uint256[] constructionCosts;
    }

    function getBuilding(uint256 buildingId) external view returns (Building memory);
}
