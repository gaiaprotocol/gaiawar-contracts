// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Battleground.sol";
import "../entities/IUnits.sol";

contract Training is OwnableUpgradeable {
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

    function trainUnits(int16 x, int16 y, uint16 unitId, uint16 quantity) external {
        require(quantity > 0, "Quantity must be greater than 0");

        Battleground.Tile memory tile = battleground.getTile(x, y);
        require(tile.owner == msg.sender, "Not the tile owner");

        uint16[] memory trainingBuildingIds = unitsContract.getTraningBuildingIds(unitId);

        bool found = false;
        for (uint256 i = 0; i < trainingBuildingIds.length; i++) {
            if (tile.buildingId == trainingBuildingIds[i]) {
                found = true;
                break;
            }
        }

        require(unitsContract.canBeTrained(unitId) && found, "Building upgrade not allowed");

        IUnits.TrainingCost[] memory costs = unitsContract.getTrainingCosts(unitId);
        for (uint256 i = 0; i < costs.length; i++) {
            require(
                costs[i].tokenAddress.transferFrom(msg.sender, address(battleground), costs[i].amount),
                "Construction cost transfer failed"
            );
        }

        battleground.addUnits(x, y, unitId, quantity);
    }
}
