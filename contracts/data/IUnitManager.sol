// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TokenAmountLib.sol";

interface IUnitManager {
    struct Unit {
        uint16 prerequisiteUnitId;
        uint16[] trainingBuildingIds;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        uint8 movementRange;
        uint16 healthBoostPercentage; // 1-10000 (0.01% - 100%)
        uint16 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountLib.TokenAmount[] trainingCost;
        TokenAmountLib.TokenAmount[] rangedAttackCost;
        bool canBeTrained;
    }

    function getUnit(uint16 unitId) external view returns (Unit memory);

    function getTotalUnitTrainingCost(uint16 unitId) external view returns (TokenAmountLib.TokenAmount[] memory);
}
