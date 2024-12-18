// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Command.sol";
import "../../data/IUnitManager.sol";
import "../../data/IBuildingManager.sol";

abstract contract AttackCommand is Command {
    IUnitManager public unitManager;
    IBuildingManager public buildingManager;

    function updateUnitManager(address _unitManager) external onlyOwner {
        unitManager = IUnitManager(_unitManager);
    }

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }
}
