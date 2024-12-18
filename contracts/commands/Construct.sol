// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/BuildingCommand.sol";
import "../libraries/CoordinatesOperations.sol";

contract Construct is BuildingCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    uint16 public headquartersSearchRange;
    uint16 public enemyBuildingSearchRange;

    function initialize(
        address _battleground,
        address _lootVault,
        address _buildingManager,
        uint16 _headquartersSearchRange,
        uint16 _enemyBuildingSearchRange
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
        headquartersSearchRange = _headquartersSearchRange;
        enemyBuildingSearchRange = _enemyBuildingSearchRange;
    }

    function updateHeadquartersSearchRange(uint16 _headquartersSearchRange) external onlyOwner {
        headquartersSearchRange = _headquartersSearchRange;
    }

    function updateEnemyBuildingSearchRange(uint16 _enemyBuildingSearchRange) external onlyOwner {
        enemyBuildingSearchRange = _enemyBuildingSearchRange;
    }

    function _getRangeCoordinates(
        IBattleground.Coordinates memory coordinates,
        uint16 range
    ) private view returns (IBattleground.Coordinates memory from, IBattleground.Coordinates memory to) {
        uint16 battlegroundWidth = battleground.width();
        uint16 battlegroundHeight = battleground.height();

        int16 minX = -int16(battlegroundWidth / 2);
        int16 maxX = int16(battlegroundWidth / 2 - 1);
        int16 minY = -int16(battlegroundHeight / 2);
        int16 maxY = int16(battlegroundHeight / 2 - 1);

        from.x = coordinates.x - int16(range);
        from.y = coordinates.y - int16(range);
        to.x = coordinates.x + int16(range);
        to.y = coordinates.y + int16(range);

        if (from.x < minX) from.x = minX;
        if (from.y < minY) from.y = minY;
        if (to.x > maxX) to.x = maxX;
        if (to.y > maxY) to.y = maxY;
    }

    function _hasNearbyHeadquarters(IBattleground.Coordinates memory coordinates) private view returns (bool) {
        (IBattleground.Coordinates memory from, IBattleground.Coordinates memory to) = _getRangeCoordinates(
            coordinates,
            headquartersSearchRange
        );

        for (int16 x = from.x; x <= to.x; x++) {
            for (int16 y = from.y; y <= to.y; y++) {
                IBattleground.Coordinates memory tileCoordinates = IBattleground.Coordinates(x, y);
                IBattleground.Tile memory tile = battleground.getTile(tileCoordinates);
                IBuildingManager.Building memory building = buildingManager.getBuilding(tile.buildingId);

                if (
                    tile.occupant == msg.sender &&
                    building.isHeadquarters &&
                    coordinates.manhattanDistance(tileCoordinates) <= building.constructionRange
                ) {
                    return true;
                }
            }
        }

        return false;
    }

    function _hasNearbyEnemies(IBattleground.Coordinates memory coordinates) private view returns (bool) {
        (IBattleground.Coordinates memory from, IBattleground.Coordinates memory to) = _getRangeCoordinates(
            coordinates,
            enemyBuildingSearchRange
        );

        for (int16 x = from.x; x <= to.x; x++) {
            for (int16 y = from.y; y <= to.y; y++) {
                IBattleground.Tile memory tile = battleground.getTile(IBattleground.Coordinates(x, y));

                if (tile.occupant != address(0) && tile.occupant != msg.sender) {
                    return true;
                }
            }
        }

        return false;
    }

    function construct(IBattleground.Coordinates memory coordinates, uint16 buildingId) external {
        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == address(0), "Tile already occupied");

        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        require(
            building.canBeConstructed && building.prerequisiteBuildingId == 0,
            "Invalid building or not constructible"
        );

        if (battleground.hasHeadquarters(msg.sender)) {
            require(_hasNearbyHeadquarters(coordinates), "No friendly HQ within range");
        } else {
            require(!_hasNearbyEnemies(coordinates), "Enemy building too close");
        }

        TokenAmountOperations.TokenAmount[] memory cost = building.constructionCost;
        cost.transferAll(msg.sender, address(lootVault));

        tile.occupant = msg.sender;
        tile.buildingId = buildingId;
        battleground.updateTile(coordinates, tile);
    }
}
