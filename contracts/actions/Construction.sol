// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Battleground.sol";
import "../entities/BuildingsInterface.sol";

contract Construction is OwnableUpgradeable {
    Battleground public battleground;
    BuildingsInterface public buildingsContract;

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
        buildingsContract = BuildingsInterface(_buildingsContract);
        headquartersSearchRange = _hqSearchRange;
        enemyBuildingSearchRange = _enemySearchRange;
    }

    function setSearchRanges(uint16 _hqSearchRange, uint16 _enemySearchRange) external onlyOwner {
        headquartersSearchRange = _hqSearchRange;
        enemyBuildingSearchRange = _enemySearchRange;
    }

    function constructBuilding(uint16 x, uint16 y, uint16 buildingId) external {
        if (battleground.hasHeadquarters(msg.sender)) {
            bool hasNearbyHeadquarters = false;

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

                    uint16 distance = uint16(dx) + uint16(dy);
                    Battleground.Tile memory tile = battleground.getTile(uint16(nx), uint16(ny));

                    if (
                        buildingsContract.isHeadquarters(tile.buildingId) &&
                        distance <= buildingsContract.getConstructionRange(tile.buildingId)
                    ) {
                        hasNearbyHeadquarters = true;
                        break;
                    }
                }
            }

            require(hasNearbyHeadquarters, "No nearby headquarters");
        } else {
            bool hasNearbyEnemyBuildings = false;

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

                    address occupant = battleground.getTile(uint16(nx), uint16(ny)).occupant;

                    if (occupant != address(0) && occupant != msg.sender) {
                        hasNearbyEnemyBuildings = true;
                        break;
                    }
                }
            }

            require(!hasNearbyEnemyBuildings, "Nearby enemy buildings");
        }

        BuildingsInterface.ConstructionCost[] memory constructionCosts = buildingsContract.getConstructionCosts(
            buildingId
        );

        for (uint256 i = 0; i < constructionCosts.length; i++) {
            BuildingsInterface.ConstructionCost memory cost = constructionCosts[i];
            require(cost.tokenAddress.transferFrom(msg.sender, address(battleground), cost.amount), "Transfer failed");
        }

        battleground.placeBuilding(x, y, msg.sender, buildingId);
    }
}
