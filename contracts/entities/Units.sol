// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IUnits.sol";

contract Units is OwnableUpgradeable, IUnits {
    struct Unit {
        uint16[] trainingBuildingIds;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        uint8 movementRange;
        TrainingCost[] trainingCosts;
        bool canBeTrained;
    }

    uint16 public nextUnitId;
    mapping(uint16 => Unit) public units;

    function canBeTrained(uint16 unitId) external view override returns (bool) {
        return units[unitId].canBeTrained;
    }

    function getTrainingBuildingIds(uint16 unitId) external view override returns (uint16[] memory) {
        return units[unitId].trainingBuildingIds;
    }

    function getTrainingCosts(uint16 unitId) external view override returns (TrainingCost[] memory) {
        return units[unitId].trainingCosts;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function addUnit(
        uint16[] calldata trainingBuildingIds,
        uint16 healthPoints,
        uint16 attackDamage,
        uint8 attackRange,
        uint8 movementRange,
        TrainingCost[] calldata trainingCosts,
        bool canBeTrained
    ) external onlyOwner {
        require(trainingBuildingIds.length > 0, "Training buildings must be provided");
        for (uint256 i = 0; i < trainingBuildingIds.length; i++) {
            require(trainingBuildingIds[i] > 0, "Training building IDs must be valid");
        }

        require(healthPoints > 0, "Health points must be greater than zero");
        require(trainingCosts.length > 0, "Training costs must be provided");

        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        units[unitId] = Unit({
            trainingBuildingIds: trainingBuildingIds,
            healthPoints: healthPoints,
            attackDamage: attackDamage,
            attackRange: attackRange,
            movementRange: movementRange,
            trainingCosts: trainingCosts,
            canBeTrained: canBeTrained
        });
    }

    function setTrainability(uint16 unitId, bool canBeTrained) external onlyOwner {
        units[unitId].canBeTrained = canBeTrained;
    }
}
