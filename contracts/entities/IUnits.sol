// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUnits {
    struct TrainingCost {
        IERC20 tokenAddress;
        uint256 amount;
    }

    function canBeTrained(uint16 unitId) external view returns (bool);

    function getTraningBuildingId(uint16 unitId) external view returns (uint16);

    function getTrainingCosts(uint16 unitId) external view returns (TrainingCost[] memory);
}
