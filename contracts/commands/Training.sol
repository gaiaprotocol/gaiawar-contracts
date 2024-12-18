// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../TokenOperations.sol";
import "../Battleground.sol";
import "../entities/IUnits.sol";

contract Training is OwnableUpgradeable {
    using TokenOperations for TokenOperations.TokenAmount[];

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

        uint16[] memory trainingBuildingIds = unitsContract.getTrainingBuildingIds(unitId);

        bool found = false;
        for (uint256 i = 0; i < trainingBuildingIds.length; i++) {
            if (tile.buildingId == trainingBuildingIds[i]) {
                found = true;
                break;
            }
        }

        require(unitsContract.canBeTrained(unitId) && found, "Unit can't be trained");

        TokenOperations.TokenAmount[] memory cost = unitsContract.getTrainingCost(unitId);
        require(cost.transferTokens(msg.sender, address(battleground)), "Training cost transfer failed");

        battleground.addUnits(x, y, unitId, quantity);
    }
}
