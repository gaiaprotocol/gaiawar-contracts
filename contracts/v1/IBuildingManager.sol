// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBuildingManager {
    struct Building {
        uint16 buildingId;
        uint16 level;
        uint16 resourceVersion;
        uint256[] totalCosts;
    }

    function getBuildingDetails(int16 _row, int16 _col) external view returns (Building memory);

    function canProduceUnit(uint16 _buildingId, uint16 _level, uint16 _unitId) external view returns (bool);
}
