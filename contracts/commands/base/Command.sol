// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../core/IBattleground.sol";
import "../../core/ILootVault.sol";

abstract contract Command is OwnableUpgradeable, UUPSUpgradeable {
    ILootVault public lootVault;
    IBattleground public battleground;

    function updateLootVault(address _lootVault) external onlyOwner {
        lootVault = ILootVault(_lootVault);
    }

    function updateBattleground(address _battleground) external onlyOwner {
        battleground = IBattleground(_battleground);
    }
}
