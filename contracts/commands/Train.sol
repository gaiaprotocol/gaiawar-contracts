// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./UnitCommand.sol";

contract Train is UnitCommand {
    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }
}
