// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IUnits.sol";

contract Units is OwnableUpgradeable, IUnits {
    struct Unit {
        uint16 trainingBuildingId;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        TrainingCost[] trainingCost;
        bool canBeTrained;
    }

    uint16 public nextUnitId;
    mapping(uint16 => Unit) public units;

    function canBeTrained(uint16 unitId) external view override returns (bool) {
        return units[unitId].canBeTrained;
    }

    function getTraningBuildingId(uint16 unitId) external view override returns (uint16) {
        return units[unitId].trainingBuildingId;
    }

    function getTrainingCosts(uint16 unitId) external view override returns (TrainingCost[] memory) {
        return units[unitId].trainingCost;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function addUnit(
        uint16 trainingBuildingId,
        uint16 healthPoints,
        uint16 attackDamage,
        uint8 attackRange,
        TrainingCost[] calldata trainingCost,
        bool canBeTrained
    ) external onlyOwner {
        require(trainingBuildingId > 0, "Training building ID must be valid");
        require(healthPoints > 0, "Health points must be greater than zero");
        require(trainingCost.length > 0, "Training costs must be provided");

        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        units[unitId] = Unit({
            trainingBuildingId: trainingBuildingId,
            healthPoints: healthPoints,
            attackDamage: attackDamage,
            attackRange: attackRange,
            trainingCost: trainingCost,
            canBeTrained: canBeTrained
        });
    }

    function setTrainability(uint16 unitId, bool canBeTrained) external onlyOwner {
        units[unitId].canBeTrained = canBeTrained;
    }
}
