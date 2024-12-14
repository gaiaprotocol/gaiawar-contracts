// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Battleground.sol";
import "../entities/IBuildings.sol";

contract Construction is OwnableUpgradeable {
    Battleground public battleground;
    IBuildings public buildingsContract;

    uint16 public headquartersSearchRange;
    uint16 public enemyBuildingSearchRange;

    function initialize(
        address _battleground,
        address _buildingsContract,
        uint16 _hqSearchRange,
        uint16 _enemySearchRange
    ) public initializer {
        __Ownable_init(msg.sender);

        battleground = Battleground(_battleground);
        buildingsContract = IBuildings(_buildingsContract);
        headquartersSearchRange = _hqSearchRange;
        enemyBuildingSearchRange = _enemySearchRange;
    }

    function setSearchRanges(uint16 _hqSearchRange, uint16 _enemySearchRange) external onlyOwner {
        headquartersSearchRange = _hqSearchRange;
        enemyBuildingSearchRange = _enemySearchRange;
    }

    function constructBuilding(uint16 x, uint16 y, uint16 buildingId) external {
        if (battleground.hasHeadquarters(msg.sender)) {
            require(_hasNearbyHeadquarters(x, y), "No nearby headquarters");
        } else {
            require(!_hasNearbyEnemies(x, y), "Nearby enemy buildings");
        }

        IBuildings.ConstructionCost[] memory costs = buildingsContract.getConstructionCosts(buildingId);
        for (uint256 i = 0; i < costs.length; i++) {
            require(
                costs[i].tokenAddress.transferFrom(msg.sender, address(battleground), costs[i].amount),
                "Cost transfer failed"
            );
        }

        battleground.placeBuilding(x, y, msg.sender, buildingId);
    }

    function _hasNearbyHeadquarters(uint16 x, uint16 y) private view returns (bool) {
        for (int16 dx = -int16(headquartersSearchRange); dx <= int16(headquartersSearchRange); dx++) {
            int16 nx = int16(x) + dx;
            if (nx < 0 || uint16(nx) >= battleground.width()) {
                continue;
            }

            for (int16 dy = -int16(headquartersSearchRange); dy <= int16(headquartersSearchRange); dy++) {
                int16 ny = int16(y) + dy;
                if (ny < 0 || uint16(ny) >= battleground.height()) {
                    continue;
                }

                uint16 absDx = dx < 0 ? uint16(-dx) : uint16(dx);
                uint16 absDy = dy < 0 ? uint16(-dy) : uint16(dy);
                uint16 distance = absDx + absDy;

                Battleground.Tile memory tile = battleground.getTile(uint16(nx), uint16(ny));
                if (tile.occupant == msg.sender && buildingsContract.isHeadquarters(tile.buildingId)) {
                    uint16 constructionRange = buildingsContract.getConstructionRange(tile.buildingId);
                    if (distance <= constructionRange) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function _hasNearbyEnemies(uint16 x, uint16 y) private view returns (bool) {
        for (int16 dx = -int16(enemyBuildingSearchRange); dx <= int16(enemyBuildingSearchRange); dx++) {
            int16 nx = int16(x) + dx;
            if (nx < 0 || uint16(nx) >= battleground.width()) {
                continue;
            }

            for (int16 dy = -int16(enemyBuildingSearchRange); dy <= int16(enemyBuildingSearchRange); dy++) {
                int16 ny = int16(y) + dy;
                if (ny < 0 || uint16(ny) >= battleground.height()) {
                    continue;
                }

                Battleground.Tile memory tile = battleground.getTile(uint16(nx), uint16(ny));
                if (tile.occupant != address(0) && tile.occupant != msg.sender) {
                    return true;
                }
            }
        }
        return false;
    }
}
