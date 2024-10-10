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

        // Fetch tile details
        address tileOccupant = mapStorage.getTileOccupant(row, col);
        uint16 tileBuildingId = mapStorage.getTileBuildingId(row, col);

        require(tileOccupant == msg.sender, "Not your tile");
        require(tileBuildingId != 0, "No building on this tile");

        // Verify building can produce the unit
        bool canProduce = buildingRegistry.canProduceUnit(tileBuildingId, unitId);
        require(canProduce, "Building cannot produce this unit");

        // Fetch unit information
        IUnitRegistry.Unit memory unitInfo = unitRegistry.getUnit(unitId);
        require(unitInfo.upgradeItemId == 0, "Unit is not a producible unit");

        // Fetch asset information
        IAssetRegistry.Asset memory asset = assetRegistry.getAsset(unitInfo.assetVersion);
        address[] memory resources = asset.resources;
        uint256[] memory costs = unitInfo.trainCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        // Calculate total costs and perform resource transfers
        for (uint256 i = 0; i < resources.length; i++) {
            uint256 totalCost = costs[i] * amount;
            IERC20 token = IERC20(resources[i]);
            require(token.transferFrom(msg.sender, address(this), totalCost), "Resource transfer failed");
        }

        // Retrieve current units on the tile
        IMapStorage.UnitAmount[] memory tileUnits = mapStorage.getTileUnits(row, col);
        uint256 unitIndex = tileUnits.length; // Default to an invalid index
        bool unitExists = false;

        // Find if the unit already exists
        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].unitId == unitId) {
                unitIndex = i;
                unitExists = true;
                break;
            }
        }

        if (unitExists) {
            // Update the existing unit amount
            tileUnits[unitIndex].amount += amount;
        } else {
            // Create a new array with an additional slot for the new unit
            IMapStorage.UnitAmount[] memory newTileUnits = new IMapStorage.UnitAmount[](tileUnits.length + 1);
            for (uint256 i = 0; i < tileUnits.length; i++) {
                newTileUnits[i] = tileUnits[i];
            }
            newTileUnits[tileUnits.length] = IMapStorage.UnitAmount({unitId: unitId, amount: amount});
            tileUnits = newTileUnits;
        }

        // Update the tile units in storage
        mapStorage.updateTileUnits(row, col, tileUnits);

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
        uint256 removeIndex = tileUnits.length; // Initialize with an invalid index

        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].unitId == preUpgradeUnitId) {
                require(tileUnits[i].amount >= amount, "Not enough units to upgrade");
                // Decrease the amount
                tileUnits[i].amount -= amount;
                if (tileUnits[i].amount == 0) {
                    removeIndex = i; // Mark this index for removal
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

        // Transfer the upgrade items
        itemToken.safeTransferFrom(msg.sender, address(this), upgradeItemId, amount, "");

        if (removeIndex < tileUnits.length) {
            // Create a new array without the removed element
            IMapStorage.UnitAmount[] memory newTileUnits = new IMapStorage.UnitAmount[](tileUnits.length - 1);
            uint256 newIndex = 0;
            for (uint256 i = 0; i < tileUnits.length; i++) {
                if (i != removeIndex) {
                    newTileUnits[newIndex] = tileUnits[i];
                    newIndex++;
                }
            }
            tileUnits = newTileUnits;
        }

        // Now, add or update the upgraded units
        bool unitExists = false;
        for (uint256 i = 0; i < tileUnits.length; i++) {
            if (tileUnits[i].unitId == unitId) {
                tileUnits[i].amount += amount;
                unitExists = true;
                break;
            }
        }
        if (!unitExists) {
            // Create a new array with an additional slot for the new unit
            IMapStorage.UnitAmount[] memory extendedTileUnits = new IMapStorage.UnitAmount[](tileUnits.length + 1);
            for (uint256 i = 0; i < tileUnits.length; i++) {
                extendedTileUnits[i] = tileUnits[i];
            }
            extendedTileUnits[tileUnits.length] = IMapStorage.UnitAmount({unitId: unitId, amount: amount});
            tileUnits = extendedTileUnits;
        }

        // Update the tile units in storage
        mapStorage.updateTileUnits(row, col, tileUnits);

        emit UnitsUpgraded(msg.sender, row, col, unitId, amount);
    }
}
