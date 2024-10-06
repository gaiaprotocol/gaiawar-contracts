// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IResourceManager.sol";

contract BuildingManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IResourceManager public resourceManager;

    event ResourceManagerSet(address indexed newResourceManager);

    function initialize(address _resourceManager) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        resourceManager = IResourceManager(_resourceManager);
        emit ResourceManagerSet(_resourceManager);
    }

    function setResourceManager(address _newResourceManager) external onlyOwner {
        resourceManager = IResourceManager(_newResourceManager);
        emit ResourceManagerSet(_newResourceManager);
    }

    struct ResourceCost {
        uint16 resourceVersion;
        uint256[] amounts;
    }

    mapping(uint16 => ResourceCost) public constructionCosts; // buildingId => costs
    mapping(uint16 => mapping(uint16 => ResourceCost)) public upgradeCosts; // buildingId => level => costs

    event ConstructionCostUpdated(uint16 indexed buildingId, uint16 resourceVersion, uint256[] amounts);
    event ConstructionCostRemoved(uint16 indexed buildingId);
    event UpgradeCostUpdated(
        uint16 indexed buildingId,
        uint16 indexed level,
        uint16 resourceVersion,
        uint256[] amounts
    );
    event UpgradeCostRemoved(uint16 indexed buildingId, uint16 indexed level);

    function updateConstructionCost(uint16 _buildingId, uint256[] memory _amounts) external onlyOwner {
        require(
            _amounts.length == resourceManager.resources(resourceManager.currentVersion()).length,
            "Invalid resource count"
        );
        constructionCosts[_buildingId] = ResourceCost({
            resourceVersion: resourceManager.currentVersion(),
            amounts: _amounts
        });
        emit ConstructionCostUpdated(_buildingId, resourceManager.currentVersion(), _amounts);
    }

    function removeConstructionCost(uint16 _buildingId) external onlyOwner {
        delete constructionCosts[_buildingId];
        emit ConstructionCostRemoved(_buildingId);
    }

    function updateUpgradeCost(uint16 _buildingId, uint16 _level, uint256[] memory _amounts) external onlyOwner {
        require(
            _amounts.length == resourceManager.resources(resourceManager.currentVersion()).length,
            "Invalid resource count"
        );
        upgradeCosts[_buildingId][_level] = ResourceCost({
            resourceVersion: resourceManager.currentVersion(),
            amounts: _amounts
        });
        emit UpgradeCostUpdated(_buildingId, _level, resourceManager.currentVersion(), _amounts);
    }

    function removeUpgradeCost(uint16 _buildingId, uint16 _level) external onlyOwner {
        delete upgradeCosts[_buildingId][_level];
        emit UpgradeCostRemoved(_buildingId, _level);
    }

    struct Building {
        uint16 buildingId;
        uint16 level;
        uint16 resourceVersion;
        uint256[] totalCosts;
    }

    mapping(int16 => mapping(int16 => Building)) public buildings; // row => col => building

    event BuildingConstructed(address indexed player, uint16 indexed buildingId, int16 row, int16 col);
    event BuildingUpgraded(address indexed player, uint16 indexed buildingId, int16 row, int16 col, uint16 newLevel);

    function constructBuilding(uint16 _buildingId, int16 _row, int16 _col) external nonReentrant {
        ResourceCost memory cost = constructionCosts[_buildingId];
        require(cost.resourceVersion > 0, "BuildingManager: Invalid building ID");

        IERC20[] memory resources = resourceManager.resources(cost.resourceVersion);
        require(cost.amounts.length == resources.length, "BuildingManager: Resource mismatch");

        for (uint8 i = 0; i < resources.length; i++) {
            require(
                resources[i].transferFrom(msg.sender, address(this), cost.amounts[i]),
                "BuildingManager: Resource transfer failed"
            );
        }

        buildings[_row][_col] = Building({
            buildingId: _buildingId,
            level: 1,
            resourceVersion: cost.resourceVersion,
            totalCosts: cost.amounts
        });

        emit BuildingConstructed(msg.sender, _buildingId, _row, _col);
    }

    function upgradeBuilding(int16 _row, int16 _col) external nonReentrant {
        Building storage building = buildings[_row][_col];
        require(building.buildingId > 0, "BuildingManager: Building does not exist");

        uint16 nextLevel = building.level + 1;
        ResourceCost memory cost = upgradeCosts[building.buildingId][nextLevel];
        require(cost.resourceVersion > 0, "BuildingManager: Invalid upgrade level");

        IERC20[] memory resources = resourceManager.resources(cost.resourceVersion);
        require(cost.amounts.length == resources.length, "BuildingManager: Resource mismatch");

        for (uint8 i = 0; i < resources.length; i++) {
            require(
                resources[i].transferFrom(msg.sender, address(this), cost.amounts[i]),
                "BuildingManager: Resource transfer failed"
            );
        }

        building.level = nextLevel;
        building.resourceVersion = cost.resourceVersion;
        for (uint8 i = 0; i < cost.amounts.length; i++) {
            building.totalCosts[i] += cost.amounts[i];
        }

        emit BuildingUpgraded(msg.sender, building.buildingId, _row, _col, nextLevel);
    }
}
