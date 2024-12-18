// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Command.sol";
import "../data/IBuildingManager.sol";

contract BuildingCommand is Command {
    IBuildingManager public buildingManager;

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }
}
