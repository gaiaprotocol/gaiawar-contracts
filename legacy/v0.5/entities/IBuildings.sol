// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../TokenOperations.sol";

interface IBuildings {
    function getParentBuildingId(uint16 buildingId) external view returns (uint16);

    function isHeadquarters(uint16 buildingId) external view returns (bool);

    function getConstructionRange(uint16 buildingId) external view returns (uint16);

    function getConstructionCost(uint16 buildingId) external view returns (TokenOperations.TokenAmount[] memory);

    function canBeConstructed(uint16 buildingId) external view returns (bool);
}
