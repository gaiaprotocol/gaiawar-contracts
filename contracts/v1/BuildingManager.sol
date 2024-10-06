// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IBuildingManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IResourceManager.sol";

contract BuildingManager is IBuildingManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
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

    struct LevelInfo {
        uint16 resourceVersion;
        uint256[] costs;
        uint16[] producibleUnits;
    }

    mapping(uint16 => mapping(uint16 => LevelInfo)) public buildingLevels; // buildingId => level => LevelInfo

    event BuildingLevelUpdated(
        uint16 indexed buildingId,
        uint16 level,
        uint16 resourceVersion,
        uint256[] costs,
        uint16[] producibleUnits
    );

    event BuildingLevelRemoved(uint16 indexed buildingId, uint16 level);

    function updateBuildingLevel(
        uint16 _buildingId,
        uint16 _level,
        uint256[] memory _costs,
        uint16[] memory _producibleUnits
    ) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        require(
            _costs.length == resourceManager.resources(resourceManager.currentVersion()).length,
            "Invalid resource count"
        );

        LevelInfo storage levelInfo = buildingLevels[_buildingId][_level];
        levelInfo.resourceVersion = resourceManager.currentVersion();
        levelInfo.costs = _costs;
        levelInfo.producibleUnits = _producibleUnits;

        emit BuildingLevelUpdated(_buildingId, _level, levelInfo.resourceVersion, _costs, _producibleUnits);
    }

    function removeBuildingLevel(uint16 _buildingId, uint16 _level) external onlyOwner {
        delete buildingLevels[_buildingId][_level];
        emit BuildingLevelRemoved(_buildingId, _level);
    }

    function canProduceUnit(uint16 _buildingId, uint16 _level, uint16 _unitId) public view returns (bool) {
        LevelInfo memory levelInfo = buildingLevels[_buildingId][_level];
        for (uint256 i = 0; i < levelInfo.producibleUnits.length; i++) {
            if (levelInfo.producibleUnits[i] == _unitId) {
                return true;
            }
        }
        return false;
    }

    mapping(int16 => mapping(int16 => Building)) public buildings; // row => col => building

    function getBuildingDetails(int16 _row, int16 _col) external view returns (Building memory) {
        return buildings[_row][_col];
    }

    event BuildingConstructed(address indexed player, uint16 indexed buildingId, int16 row, int16 col);
    event BuildingUpgraded(address indexed player, uint16 indexed buildingId, int16 row, int16 col, uint16 newLevel);

    function constructBuilding(uint16 _buildingId, int16 _row, int16 _col) external nonReentrant {
        require(buildings[_row][_col].buildingId == 0, "BuildingManager: Location already occupied");

        LevelInfo memory levelInfo = buildingLevels[_buildingId][1];
        require(levelInfo.resourceVersion > 0, "BuildingManager: Invalid building ID or level not set");

        IERC20[] memory resources = resourceManager.resources(levelInfo.resourceVersion);
        require(levelInfo.costs.length == resources.length, "BuildingManager: Resource mismatch");

        for (uint8 i = 0; i < resources.length; i++) {
            require(
                resources[i].transferFrom(msg.sender, address(this), levelInfo.costs[i]),
                "BuildingManager: Resource transfer failed"
            );
        }

        buildings[_row][_col] = Building({
            buildingId: _buildingId,
            level: 1,
            resourceVersion: levelInfo.resourceVersion,
            totalCosts: levelInfo.costs
        });

        emit BuildingConstructed(msg.sender, _buildingId, _row, _col);
    }

    function upgradeBuilding(int16 _row, int16 _col) external nonReentrant {
        Building storage building = buildings[_row][_col];
        require(building.buildingId > 0, "BuildingManager: Building does not exist");

        uint16 nextLevel = building.level + 1;

        LevelInfo memory levelInfo = buildingLevels[building.buildingId][nextLevel];
        require(levelInfo.resourceVersion > 0, "BuildingManager: Invalid upgrade level");

        IERC20[] memory resources = resourceManager.resources(levelInfo.resourceVersion);
        require(levelInfo.costs.length == resources.length, "BuildingManager: Resource mismatch");

        for (uint8 i = 0; i < resources.length; i++) {
            require(
                resources[i].transferFrom(msg.sender, address(this), levelInfo.costs[i]),
                "BuildingManager: Resource transfer failed"
            );
        }

        building.level = nextLevel;
        building.resourceVersion = levelInfo.resourceVersion;
        for (uint8 i = 0; i < levelInfo.costs.length; i++) {
            building.totalCosts[i] += levelInfo.costs[i];
        }

        emit BuildingUpgraded(msg.sender, building.buildingId, _row, _col, nextLevel);
    }
}
