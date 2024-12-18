// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IAssetRegistry.sol";
import "./IBuildingRegistry.sol";
import "./IMapStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstructionManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAssetRegistry public assetRegistry;
    IBuildingRegistry public buildingRegistry;
    IMapStorage public mapStorage;

    event AssetRegistrySet(address assetRegistry);
    event BuildingRegistrySet(address buildingRegistry);
    event MapStorageSet(address mapStorage);
    event BuildingConstructed(address indexed player, uint16 row, uint16 col, uint256 buildingId);

    function initialize(address _assetRegistry, address _buildingRegistry, address _mapStorage) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        assetRegistry = IAssetRegistry(_assetRegistry);
        buildingRegistry = IBuildingRegistry(_buildingRegistry);
        mapStorage = IMapStorage(_mapStorage);

        emit AssetRegistrySet(_assetRegistry);
        emit BuildingRegistrySet(_buildingRegistry);
        emit MapStorageSet(_mapStorage);
    }

    function setAssetRegistry(address _assetRegistry) external onlyOwner {
        assetRegistry = IAssetRegistry(_assetRegistry);

        emit AssetRegistrySet(_assetRegistry);
    }

    function setBuildingRegistry(address _buildingRegistry) external onlyOwner {
        buildingRegistry = IBuildingRegistry(_buildingRegistry);

        emit BuildingRegistrySet(_buildingRegistry);
    }

    function setMapStorage(address _mapStorage) external onlyOwner {
        mapStorage = IMapStorage(_mapStorage);

        emit MapStorageSet(_mapStorage);
    }

    function constructBuilding(uint16 row, uint16 col, uint16 buildingId) external nonReentrant {
        IBuildingRegistry.Building memory building = buildingRegistry.getBuilding(buildingId);
        address tileOccupant = mapStorage.getTileOccupant(row, col);
        uint16 tileBuildingId = mapStorage.getTileBuildingId(row, col);

        require(tileOccupant == address(0) || tileOccupant == msg.sender, "Tile occupied by another player");
        require(tileBuildingId == 0, "Building already exists on this tile");

        if (building.isHeadquarters) {
            require(!isWithinEnemyBuildingRange(row, col, 3), "Cannot build near enemy building");
        } else {
            require(isWithinPlayerHeadquartersRange(msg.sender, row, col, 7), "Cannot build outside of allowed range");
            require(!isWithinEnemyBuildingRange(row, col, 3), "Cannot build near enemy building");
        }

        deductConstructionCosts(building);

        mapStorage.updateTileOccupant(row, col, msg.sender);
        mapStorage.updateTileBuildingId(row, col, buildingId);

        emit BuildingConstructed(msg.sender, row, col, buildingId);
    }

    function calculateDistance(
        uint16 fromRow,
        uint16 fromCol,
        uint16 toRow,
        uint16 toCol
    ) internal pure returns (uint16) {
        uint16 rowDistance = fromRow > toRow ? fromRow - toRow : toRow - fromRow;
        uint16 colDistance = fromCol > toCol ? fromCol - toCol : toCol - fromCol;
        return rowDistance + colDistance;
    }

    function isWithinEnemyBuildingRange(uint16 row, uint16 col, uint16 range) internal view returns (bool) {
        uint16 startRow = row >= range ? row - range : 0;
        uint16 endRow = row + range < mapStorage.mapRows() ? row + range : mapStorage.mapRows() - 1;
        uint16 startCol = col >= range ? col - range : 0;
        uint16 endCol = col + range < mapStorage.mapCols() ? col + range : mapStorage.mapCols() - 1;

        for (uint16 i = startRow; i <= endRow; i++) {
            for (uint16 j = startCol; j <= endCol; j++) {
                uint16 distance = calculateDistance(row, col, i, j);
                if (distance <= range) {
                    address tileOccupant = mapStorage.getTileOccupant(i, j);
                    uint16 tileBuildingId = mapStorage.getTileBuildingId(i, j);
                    if (tileOccupant != address(0) && tileOccupant != msg.sender && tileBuildingId != 0) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function isWithinPlayerHeadquartersRange(
        address player,
        uint16 row,
        uint16 col,
        uint16 range
    ) internal view returns (bool) {
        uint16 startRow = row >= range ? row - range : 0;
        uint16 endRow = row + range < mapStorage.mapRows() ? row + range : mapStorage.mapRows() - 1;
        uint16 startCol = col >= range ? col - range : 0;
        uint16 endCol = col + range < mapStorage.mapCols() ? col + range : mapStorage.mapCols() - 1;

        for (uint16 i = startRow; i <= endRow; i++) {
            for (uint16 j = startCol; j <= endCol; j++) {
                address tileOccupant = mapStorage.getTileOccupant(i, j);
                uint16 tileBuildingId = mapStorage.getTileBuildingId(i, j);

                if (tileOccupant == player && tileBuildingId != 0) {
                    IBuildingRegistry.Building memory building = buildingRegistry.getBuilding(tileBuildingId);
                    if (building.isHeadquarters) {
                        uint16 distance = calculateDistance(row, col, i, j);
                        if (distance <= range) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    function deductConstructionCosts(IBuildingRegistry.Building memory building) internal {
        IAssetRegistry.Asset memory asset = assetRegistry.getAsset(building.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = building.constructionCosts;

        require(resources.length == costs.length, "Resource and cost length mismatch");

        for (uint256 i = 0; i < resources.length; i++) {
            IERC20 token = IERC20(resources[i]);
            require(token.transferFrom(msg.sender, address(mapStorage), costs[i]), "Resource transfer failed");
        }
    }

    function upgradeBuilding(uint16 row, uint16 col, uint16 newBuildingId) external nonReentrant {
        address tileOccupant = mapStorage.getTileOccupant(row, col);
        uint16 tileBuildingId = mapStorage.getTileBuildingId(row, col);

        require(tileOccupant == msg.sender, "Not your building");
        require(tileBuildingId != 0, "No building on this tile");

        IBuildingRegistry.Building memory currentBuilding = buildingRegistry.getBuilding(tileBuildingId);
        IBuildingRegistry.Building memory upgradedBuilding = buildingRegistry.getBuilding(newBuildingId);

        require(currentBuilding.level < upgradedBuilding.level, "Invalid upgrade");
        require(currentBuilding.isHeadquarters == upgradedBuilding.isHeadquarters, "Cannot change building type");
        require(upgradedBuilding.preUpgradeBuildingId == tileBuildingId, "Invalid upgrade path");

        deductConstructionCosts(upgradedBuilding);

        mapStorage.updateTileBuildingId(row, col, newBuildingId);

        emit BuildingConstructed(msg.sender, row, col, newBuildingId);
    }
}
