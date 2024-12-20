// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TokenAmountLib.sol";

interface IBuildingManager {
    struct Building {
        uint16 prerequisiteBuildingId;
        bool isHeadquarters;
        uint16 constructionRange;
        uint16 healthBoostPercentage; // 1-10000 (0.01% - 100%)
        uint16 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountLib.TokenAmount[] constructionCost;
        bool canBeConstructed;
    }

    function getBuilding(uint16 buildingId) external view returns (Building memory);

    function getTotalBuildingConstructionCost(
        uint16 buildingId
    ) external view returns (TokenAmountLib.TokenAmount[] memory);
}
