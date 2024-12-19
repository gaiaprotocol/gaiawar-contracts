// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./base/BuildingCommand.sol";

contract UpgradeBuilding is BuildingCommand, ReentrancyGuardUpgradeable {
    using TokenAmountLib for TokenAmountLib.TokenAmount[];

    function initialize(address _battleground, address _lootVault, address _buildingManager) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function upgradeBuilding(IBattleground.Coordinates memory coordinates, uint16 buildingId) external nonReentrant {
        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Only tile occupant can upgrade building");

        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        require(
            building.canBeConstructed && building.prerequisiteBuildingId == tile.buildingId,
            "Building upgrade not allowed"
        );

        TokenAmountLib.TokenAmount[] memory cost = building.constructionCost;
        cost.transferAll(msg.sender, address(lootVault));

        tile.buildingId = buildingId;
        battleground.updateTile(coordinates, tile);
    }
}
