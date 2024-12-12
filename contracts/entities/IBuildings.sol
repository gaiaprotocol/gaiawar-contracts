// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBuildings {
    struct ConstructionCost {
        IERC20 tokenAddress;
        uint256 amount;
    }

    function isHeadquarters(uint16 buildingId) external view returns (bool);

    function getConstructionRange(uint16 buildingId) external view returns (uint16);

    function getConstructionCosts(uint16 buildingId) external view returns (ConstructionCost[] memory);

    function canBeConstructed(uint16 buildingId) external view returns (bool);
}
