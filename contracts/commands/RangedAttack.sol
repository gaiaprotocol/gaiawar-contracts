// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./AttackCommand.sol";

contract RangedAttack is AttackCommand {
    function initialize(
        address _battleground,
        address _lootVault,
        address _unitManager,
        address _buildingManager
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
        buildingManager = IBuildingManager(_buildingManager);
    }
}
