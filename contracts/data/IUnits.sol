// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUnits {
    struct Cost {
        IERC20 token;
        uint256 amount;
    }

    struct Unit {
        uint16[] trainingBuildingIds;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        uint8 movementRange;
        uint16 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        Cost[] trainingCost;
        Cost[] rangedAttackCost;
        bool canBeTrained;
    }

    function getUnit(uint16 unitId) external view returns (Unit memory);
}
