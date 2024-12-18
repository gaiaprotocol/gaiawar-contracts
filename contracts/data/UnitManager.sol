// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IUnitManager.sol";

contract UnitManager is OwnableUpgradeable, IUnitManager {
    uint16 public nextUnitId;
    mapping(uint16 => Unit) public units;

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function addUnit(Unit calldata unit) external onlyOwner {
        require(unit.trainingBuildingIds.length > 0, "Training building IDs must be provided");
        for (uint256 i = 0; i < unit.trainingBuildingIds.length; i++) {
            require(unit.trainingBuildingIds[i] > 0, "Training building IDs must be valid");
        }

        require(unit.healthPoints > 0, "Health points must be greater than 0");
        require(unit.trainingCost.length > 0, "Training cost must be provided");

        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        units[unitId] = unit;
    }

    function setTrainability(uint16 unitId, bool canBeTrained) external onlyOwner {
        require(unitId < nextUnitId, "Unit does not exist");

        units[unitId].canBeTrained = canBeTrained;
    }

    function getUnit(uint16 unitId) external view override returns (Unit memory) {
        return units[unitId];
    }
}