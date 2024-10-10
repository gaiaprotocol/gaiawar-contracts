// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IAssetRegistry.sol";
import "./IUnitRegistry.sol";
import "./IBuildingRegistry.sol";
import "./IMapStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract TrainingManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAssetRegistry public assetRegistry;
    IUnitRegistry public unitRegistry;
    IBuildingRegistry public buildingRegistry;
    IMapStorage public mapStorage;

    event AssetRegistrySet(address assetRegistry);
    event UnitRegistrySet(address unitRegistry);
    event BuildingRegistrySet(address buildingRegistry);
    event MapStorageSet(address mapStorage);

    event UnitsTrained(address indexed player, uint16 row, uint16 col, uint16 unitId, uint16 amount);
    event UnitsUpgraded(address indexed player, uint16 row, uint16 col, uint16 unitId, uint16 amount);

    function initialize(
        address _assetRegistry,
        address _unitRegistry,
        address _buildingRegistry,
        address _mapStorage
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        assetRegistry = IAssetRegistry(_assetRegistry);
        unitRegistry = IUnitRegistry(_unitRegistry);
        buildingRegistry = IBuildingRegistry(_buildingRegistry);
        mapStorage = IMapStorage(_mapStorage);

        emit AssetRegistrySet(_assetRegistry);
        emit UnitRegistrySet(_unitRegistry);
        emit BuildingRegistrySet(_buildingRegistry);
        emit MapStorageSet(_mapStorage);
    }

    function setAssetRegistry(address _assetRegistry) external onlyOwner {
        assetRegistry = IAssetRegistry(_assetRegistry);

        emit AssetRegistrySet(_assetRegistry);
    }

    function setUnitRegistry(address _unitRegistry) external onlyOwner {
        unitRegistry = IUnitRegistry(_unitRegistry);

        emit UnitRegistrySet(_unitRegistry);
    }

    function setBuildingRegistry(address _buildingRegistry) external onlyOwner {
        buildingRegistry = IBuildingRegistry(_buildingRegistry);

        emit BuildingRegistrySet(_buildingRegistry);
    }

    function setMapStorage(address _mapStorage) external onlyOwner {
        mapStorage = IMapStorage(_mapStorage);

        emit MapStorageSet(_mapStorage);
    }

    function trainUnits(uint16 row, uint16 col, uint16 unitId, uint16 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        address tileOccupant = mapStorage.getTileOccupant(row, col);
        uint16 tileBuildingId = mapStorage.getTileBuildingId(row, col);

        require(tileOccupant == msg.sender, "Not your tile");
        require(tileBuildingId != 0, "No building on this tile");

        bool canProduce = buildingRegistry.canProduceUnit(tileBuildingId, unitId);
        require(canProduce, "Building cannot produce this unit");

        IUnitRegistry.Unit memory unitInfo = unitRegistry.getUnit(unitId);
        require(unitInfo.upgradeItemId == 0, "Unit is not a producible unit");

        IAssetRegistry.Asset memory asset = assetRegistry.getAsset(unitInfo.assetVersion);
        address[] memory resources = asset.resources;
        uint256[] memory costs = unitInfo.trainCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 i = 0; i < resources.length; i++) {
            uint256 totalCost = costs[i] * amount;
            IERC20 token = IERC20(resources[i]);
            require(token.transferFrom(msg.sender, address(this), totalCost), "Resource transfer failed");
        }

        IMapStorage.UnitAmount[] memory tileUnits = mapStorage.getTileUnits(row, col);

        bool unitExists = false;
        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].unitId == unitId) {
                tileUnits[i].amount += amount;
                unitExists = true;
                break;
            }
        }

        if (unitExists) {
            mapStorage.updateTileUnits(row, col, tileUnits);
        } else {
            IMapStorage.UnitAmount[] memory newTileUnits = new IMapStorage.UnitAmount[](tileUnits.length + 1);
            for (uint256 i = 0; i < tileUnits.length; i++) {
                newTileUnits[i] = tileUnits[i];
            }
            newTileUnits[tileUnits.length] = IMapStorage.UnitAmount({unitId: unitId, amount: amount});
            mapStorage.updateTileUnits(row, col, newTileUnits);
        }

        emit UnitsTrained(msg.sender, row, col, unitId, amount);
    }

    function upgradeUnits(uint16 row, uint16 col, uint16 unitId, uint16 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");

        address tileOccupant = mapStorage.getTileOccupant(row, col);
        require(tileOccupant == msg.sender, "Not your tile");

        IUnitRegistry.Unit memory unitInfo = unitRegistry.getUnit(unitId);
        require(unitInfo.preUpgradeUnitId != 0, "Unit cannot be upgraded");

        uint16 preUpgradeUnitId = unitInfo.preUpgradeUnitId;
        IMapStorage.UnitAmount[] memory tileUnits = mapStorage.getTileUnits(row, col);

        bool found = false;
        uint256 newLength = tileUnits.length;
        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].unitId == preUpgradeUnitId) {
                require(tileUnits[i].amount >= amount, "Not enough units to upgrade");
                tileUnits[i].amount -= amount;
                if (tileUnits[i].amount == 0) {
                    newLength--;
                }
                found = true;
                break;
            }
        }
        require(found, "No units to upgrade");

        uint256 upgradeItemId = unitInfo.upgradeItemId;
        require(upgradeItemId != 0, "No upgrade item required");

        IAssetRegistry.Asset memory asset = assetRegistry.getAsset(unitInfo.assetVersion);
        address itemAddress = asset.item;
        IERC1155 itemToken = IERC1155(itemAddress);

        itemToken.safeTransferFrom(msg.sender, address(this), upgradeItemId, amount, "");

        IMapStorage.UnitAmount[] memory newTileUnits = new IMapStorage.UnitAmount[](newLength);
        uint256 index = 0;
        bool upgradedUnitExists = false;

        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].amount > 0) {
                if (tileUnits[i].unitId == unitId) {
                    newTileUnits[index] = IMapStorage.UnitAmount({
                        unitId: unitId,
                        amount: tileUnits[i].amount + amount
                    });
                    upgradedUnitExists = true;
                } else {
                    newTileUnits[index] = tileUnits[i];
                }
                index++;
            }
        }

        if (!upgradedUnitExists) {
            require(index < newLength, "Array bounds exceeded");
            newTileUnits[index] = IMapStorage.UnitAmount({unitId: unitId, amount: amount});
        }

        mapStorage.updateTileUnits(row, col, newTileUnits);

        emit UnitsUpgraded(msg.sender, row, col, unitId, amount);
    }
}
