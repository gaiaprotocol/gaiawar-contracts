// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IResourceManager.sol";
import "./IBuildingManager.sol";

contract UnitManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IResourceManager public resourceManager;
    IBuildingManager public buildingManager;

    event ResourceManagerSet(address indexed newResourceManager);
    event BuildingManagerSet(address indexed newBuildingManager);

    function initialize(address _resourceManager, address _buildingManager) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        resourceManager = IResourceManager(_resourceManager);
        buildingManager = IBuildingManager(_buildingManager);
        emit ResourceManagerSet(_resourceManager);
        emit BuildingManagerSet(_buildingManager);
    }

    function setResourceManager(address _newResourceManager) external onlyOwner {
        resourceManager = IResourceManager(_newResourceManager);
        emit ResourceManagerSet(_newResourceManager);
    }

    function setBuildingManager(address _newBuildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_newBuildingManager);
        emit BuildingManagerSet(_newBuildingManager);
    }

    struct UnitCost {
        uint16 resourceVersion;
        uint256[] amounts;
    }

    mapping(uint16 => UnitCost) public unitCosts; // unitId => costs

    event UnitCostUpdated(uint16 indexed unitId, uint16 resourceVersion, uint256[] amounts);
    event UnitCostRemoved(uint16 indexed unitId);

    function updateUnitCost(uint16 _unitId, uint256[] memory _amounts) external onlyOwner {
        require(
            _amounts.length == resourceManager.resources(resourceManager.currentVersion()).length,
            "Invalid resource count"
        );
        unitCosts[_unitId] = UnitCost({resourceVersion: resourceManager.currentVersion(), amounts: _amounts});
        emit UnitCostUpdated(_unitId, resourceManager.currentVersion(), _amounts);
    }

    function removeUnitCost(uint16 _unitId) external onlyOwner {
        delete unitCosts[_unitId];
        emit UnitCostRemoved(_unitId);
    }

    struct Unit {
        uint16 unitId;
        uint256 creationTime;
    }

    mapping(address => mapping(uint256 => Unit)) public playerUnits; // player => unitIndex => Unit
    mapping(address => uint256) public playerUnitCount;

    event UnitCreated(address indexed player, uint16 indexed unitId, uint256 indexed unitIndex);

    function createUnit(uint16 _unitId, int16 _buildingRow, int16 _buildingCol) external nonReentrant {
        IBuildingManager.Building memory building = buildingManager.getBuildingDetails(_buildingRow, _buildingCol);
        require(building.buildingId > 0, "UnitManager: Building does not exist");

        bool canProduce = buildingManager.canProduceUnit(building.buildingId, building.level, _unitId);
        require(canProduce, "UnitManager: Cannot create this unit in this building");

        UnitCost memory cost = unitCosts[_unitId];
        require(cost.resourceVersion > 0, "UnitManager: Invalid unit ID");

        IERC20[] memory resources = resourceManager.resources(cost.resourceVersion);
        require(cost.amounts.length == resources.length, "UnitManager: Resource mismatch");

        for (uint8 i = 0; i < resources.length; i++) {
            require(
                resources[i].transferFrom(msg.sender, address(this), cost.amounts[i]),
                "UnitManager: Resource transfer failed"
            );
        }

        uint256 unitIndex = playerUnitCount[msg.sender];
        playerUnits[msg.sender][unitIndex] = Unit({unitId: _unitId, creationTime: block.timestamp});
        playerUnitCount[msg.sender]++;

        emit UnitCreated(msg.sender, _unitId, unitIndex);
    }
}
