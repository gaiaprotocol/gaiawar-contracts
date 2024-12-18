// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TokenAmountOperations.sol";

interface IUnitManager {
    struct Unit {
        uint16 prerequisiteUnitId;
        uint16[] trainingBuildingIds;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        uint8 movementRange;
        uint16 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountOperations.TokenAmount[] trainingCost;
        TokenAmountOperations.TokenAmount[] rangedAttackCost;
        bool canBeTrained;
    }

    function getUnit(uint16 unitId) external view returns (Unit memory);

    function getTotalUnitTrainingCost(uint16 unitId) external view returns (TokenAmountOperations.TokenAmount[] memory);
}
