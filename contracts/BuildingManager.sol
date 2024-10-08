// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IBuildingManager.sol";
import "./IAssetManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract BuildingManager is IBuildingManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    mapping(uint256 => Building) public buildings;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function getBuilding(uint256 buildingId) external view override returns (Building memory) {
        return buildings[buildingId];
    }

    function addBuilding(
        uint256 buildingId,
        uint16 assetVersion,
        uint256 preUpgradeBuildingId,
        uint256[] calldata constructionCosts
    ) external onlyOwner {
        require(buildings[buildingId].assetVersion == 0, "Building already exists");

        buildings[buildingId] = Building({
            assetVersion: assetVersion,
            preUpgradeBuildingId: preUpgradeBuildingId,
            constructionCosts: constructionCosts
        });
    }
}
