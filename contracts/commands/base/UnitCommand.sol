// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Command.sol";
import "../../data/IUnitManager.sol";

abstract contract UnitCommand is Command {
    IUnitManager public unitManager;

    function updateUnitManager(address _unitManager) external onlyOwner {
        unitManager = IUnitManager(_unitManager);
    }
}
