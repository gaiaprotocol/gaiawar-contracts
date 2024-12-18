// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../core/IBattleground.sol";

abstract contract Command is OwnableUpgradeable {
    IBattleground public battleground;

    function updateBattleground(address _battleground) external onlyOwner {
        battleground = IBattleground(_battleground);
    }
}
