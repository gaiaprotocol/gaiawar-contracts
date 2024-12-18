// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../TokenOperations.sol";

interface IUnits {
    function getTrainingBuildingIds(uint16 unitId) external view returns (uint16[] memory);

    function getHealthPoints(uint16 unitId) external view returns (uint16);

    function getAttackDamage(uint16 unitId) external view returns (uint16);

    function getAttackRange(uint16 unitId) external view returns (uint8);

    function getTrainingCost(uint16 unitId) external view returns (TokenOperations.TokenAmount[] memory);

    function getRangedAttackCost(uint16 unitId) external view returns (TokenOperations.TokenAmount[] memory);

    function canBeTrained(uint16 unitId) external view returns (bool);
}
