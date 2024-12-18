// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../TokenOperations.sol";

interface IUnits {
    function canBeTrained(uint16 unitId) external view returns (bool);

    function getTrainingBuildingIds(uint16 unitId) external view returns (uint16[] memory);

    function getTrainingCost(uint16 unitId) external view returns (TokenOperations.TokenAmount[] memory);
}
