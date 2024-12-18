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

    function applyDamageToUnits(
        Battleground.UnitQuantity[] memory units,
        uint256 damage
    ) private view returns (Battleground.UnitQuantity[] memory remainingUnits, uint256 totalRemainingUnits) {
        uint256 remainingUnitsLength = 0;

        for (uint256 i = 0; i < units.length; i++) {
            uint16 hp = unitsContract.getHealthPoints(units[i].unitId);
            uint16 killedUnits = uint16(damage / hp);
            if (killedUnits == 0) {
                totalRemainingUnits += units[i].quantity;
                continue;
            }
            if (killedUnits > units[i].quantity) {
                killedUnits = units[i].quantity;
            }
            units[i].quantity -= killedUnits;
            if (units[i].quantity > 0) {
                remainingUnitsLength++;
                totalRemainingUnits += units[i].quantity;
            }
            damage -= uint256(killedUnits) * uint256(hp);
        }

        remainingUnits = new Battleground.UnitQuantity[](remainingUnitsLength);

        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i].quantity > 0) {
                remainingUnits[index] = units[i];
                index++;
            }
        }
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
