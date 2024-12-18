// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TokenAmountOperations.sol";

interface IBuildingManager {
    struct Building {
        uint16 prerequisiteBuildingId;
        bool isHeadquarters;
        uint16 constructionRange;
        uint256 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountOperations.TokenAmount[] constructionCost;
        bool canBeConstructed;
    }

    function getBuilding(uint16 buildingId) external view returns (Building memory);

    function getTotalBuildingConstructionCost(
        uint16 buildingId
    ) external view returns (TokenAmountOperations.TokenAmount[] memory);
}
