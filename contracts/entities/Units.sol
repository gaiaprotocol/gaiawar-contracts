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
        uint16 damageBuffPercentage; // 1-10000 (0.01% - 100%)
        TokenOperations.TokenAmount[] trainingCost;
        TokenOperations.TokenAmount[] rangedAttackCost;
        bool canBeTrained;
    }

    uint16 public nextUnitId;
    mapping(uint16 => Unit) public units;

    function getTrainingBuildingIds(uint16 unitId) external view override returns (uint16[] memory) {
        return units[unitId].trainingBuildingIds;
    }

    function getHealthPoints(uint16 unitId) external view override returns (uint16) {
        return units[unitId].healthPoints;
    }

    function getAttackDamage(uint16 unitId) external view override returns (uint16) {
        return units[unitId].attackDamage;
    }

    function getAttackRange(uint16 unitId) external view override returns (uint8) {
        return units[unitId].attackRange;
    }

    function getMovementRange(uint16 unitId) external view override returns (uint8) {
        return units[unitId].movementRange;
    }

    function getTrainingCost(uint16 unitId) external view override returns (TokenOperations.TokenAmount[] memory) {
        return units[unitId].trainingCost;
    }

    function getRangedAttackCost(uint16 unitId) external view returns (TokenOperations.TokenAmount[] memory) {
        return units[unitId].rangedAttackCost;
    }

    function canBeTrained(uint16 unitId) external view override returns (bool) {
        return units[unitId].canBeTrained;
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
        uint16 damageBuffPercentage,
        TokenOperations.TokenAmount[] calldata trainingCost,
        TokenOperations.TokenAmount[] calldata rangedAttackCost,
        bool canBeTrained
    ) external onlyOwner {
        require(trainingBuildingIds.length > 0, "Training buildings must be provided");
        for (uint256 i = 0; i < trainingBuildingIds.length; i++) {
            require(trainingBuildingIds[i] > 0, "Training building IDs must be valid");
        }

        require(healthPoints > 0, "Health points must be greater than zero");
        require(trainingCost.length > 0, "Training cost must be provided");
        require(rangedAttackCost.length > 0, "Ranged attack cost must be provided");

        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        units[unitId] = Unit({
            trainingBuildingIds: trainingBuildingIds,
            healthPoints: healthPoints,
            attackDamage: attackDamage,
            attackRange: attackRange,
            movementRange: movementRange,
            damageBuffPercentage: damageBuffPercentage,
            trainingCost: trainingCost,
            rangedAttackCost: rangedAttackCost,
            canBeTrained: canBeTrained
        });
    }

    function setTrainability(uint16 unitId, bool canBeTrained) external onlyOwner {
        units[unitId].canBeTrained = canBeTrained;
    }
}
