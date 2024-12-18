// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Battleground.sol";
import "../entities/IUnits.sol";

contract Attack is OwnableUpgradeable {
    Battleground public battleground;
    IUnits public unitsContract;

    function initialize(address _battleground, address _unitsContract) public initializer {
        __Ownable_init(msg.sender);

        battleground = Battleground(_battleground);
        unitsContract = IUnits(_unitsContract);
    }

    function setBattleground(address _battleground) external onlyOwner {
        battleground = Battleground(_battleground);
    }

    function moveAndAttack(
        int16 fromX,
        int16 fromY,
        int16 toX,
        int16 toY,
        uint16[] calldata unitIds,
        uint16[] calldata quantities
    ) external {
        require(unitIds.length == quantities.length, "UnitIds and quantities length mismatch");

        //TODO:
    }

    function rangedAttack(
        int16 fromX,
        int16 fromY,
        int16 toX,
        int16 toY,
        uint16[] calldata unitIds,
        uint16[] calldata quantities
    ) external {
        require(unitIds.length == quantities.length, "UnitIds and quantities length mismatch");

        //TODO:
    }
}
