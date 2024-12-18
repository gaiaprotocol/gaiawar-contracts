// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/BuildingCommand.sol";

contract UpgradeBuilding is BuildingCommand {
    function initialize(address _battleground, address _lootVault, address _buildingManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
    }
}
