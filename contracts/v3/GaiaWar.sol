// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IAssetManager.sol";
import "./IBuildingManager.sol";
import "./IUnitManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract GaiaWar is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC165, IERC1155Receiver {
    IAssetManager public assetManager;
    IBuildingManager public buildingManager;
    IUnitManager public unitManager;

    uint16 public mapRows;
    uint16 public mapCols;
    uint16 public maxUnitsPerTile;
    uint16 public maxUnitMovementRange;
    uint8 public maxBattleRounds;
    uint8 public ownerSharePercentage;

    struct UnitAmount {
        uint16 unitId;
        uint16 amount;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitAmount[] units;
    }

    mapping(uint16 => mapping(uint16 => Tile)) public map;

    event AssetManagerSet(address indexed newAssetManager);
    event BuildingManagerSet(address indexed newBuildingManager);
    event UnitManagerSet(address indexed newUnitManager);
    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);
    event MaxUnitMovementRangeUpdated(uint16 newMaxRange);
    event MaxBattleRoundsUpdated(uint8 newMaxRounds);
    event OwnerSharePercentageUpdated(uint8 newPercentage);
    event UnitsMoved(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol, UnitAmount[] units);
    event AttackResult(
        address indexed attacker,
        address indexed defender,
        uint16 fromRow,
        uint16 fromCol,
        uint16 toRow,
        uint16 toCol,
        bool attackerWon
    );
    event BuildingConstructed(address indexed player, uint16 row, uint16 col, uint256 buildingId);
    event UnitsTrained(address indexed player, uint16 row, uint16 col, uint16 unitId, uint16 amount);
    event UnitsUpgraded(address indexed player, uint16 row, uint16 col, uint16 unitId, uint16 amount);

    function initialize(
        address _assetManager,
        address _buildingManager,
        address _unitManager,
        uint16 _mapRows,
        uint16 _mapCols,
        uint16 _maxUnitsPerTile,
        uint16 _maxUnitMovementRange,
        uint8 _maxBattleRounds,
        uint8 _ownerSharePercentage
    ) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        assetManager = IAssetManager(_assetManager);
        buildingManager = IBuildingManager(_buildingManager);
        unitManager = IUnitManager(_unitManager);
        mapRows = _mapRows;
        mapCols = _mapCols;
        maxUnitsPerTile = _maxUnitsPerTile;
        maxUnitMovementRange = _maxUnitMovementRange;
        maxBattleRounds = _maxBattleRounds;
        ownerSharePercentage = _ownerSharePercentage;

        emit AssetManagerSet(_assetManager);
        emit BuildingManagerSet(_buildingManager);
        emit UnitManagerSet(_unitManager);
        emit MapSizeUpdated(_mapRows, _mapCols);
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
        emit MaxUnitMovementRangeUpdated(_maxUnitMovementRange);
        emit MaxBattleRoundsUpdated(_maxBattleRounds);
        emit OwnerSharePercentageUpdated(_ownerSharePercentage);
    }

    function setAssetManager(address _newAssetManager) external onlyOwner {
        assetManager = IAssetManager(_newAssetManager);
        emit AssetManagerSet(_newAssetManager);
    }

    function setBuildingManager(address _newBuildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_newBuildingManager);
        emit BuildingManagerSet(_newBuildingManager);
    }

    function setUnitManager(address _newUnitManager) external onlyOwner {
        unitManager = IUnitManager(_newUnitManager);
        emit UnitManagerSet(_newUnitManager);
    }

    function setMapSize(uint16 _newRows, uint16 _newCols) external onlyOwner {
        mapRows = _newRows;
        mapCols = _newCols;
        emit MapSizeUpdated(_newRows, _newCols);
    }

    function setMaxUnitsPerTile(uint16 _newMaxUnits) external onlyOwner {
        maxUnitsPerTile = _newMaxUnits;
        emit MaxUnitsPerTileUpdated(_newMaxUnits);
    }

    function setMaxUnitMovementRange(uint16 _newMaxRange) external onlyOwner {
        maxUnitMovementRange = _newMaxRange;
        emit MaxUnitMovementRangeUpdated(_newMaxRange);
    }

    function setOwnerSharePercentage(uint8 _newPercentage) external onlyOwner {
        ownerSharePercentage = _newPercentage;
        emit OwnerSharePercentageUpdated(_newPercentage);
    }

    function getTileUnits(uint16 row, uint16 col) external view returns (UnitAmount[] memory) {
        require(row < mapRows, "Invalid row");
        require(col < mapCols, "Invalid column");
        return map[row][col].units;
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

    function moveUnits(
        uint16 fromRow,
        uint16 fromCol,
        uint16 toRow,
        uint16 toCol,
        UnitAmount[] calldata unitsToMove
    ) external {
        require(fromRow < mapRows && fromCol < mapCols, "Invalid from coordinates");
        require(toRow < mapRows && toCol < mapCols, "Invalid to coordinates");

        uint16 distance = calculateDistance(fromRow, fromCol, toRow, toCol);
        require(distance <= maxUnitMovementRange, "Movement range exceeded");

        Tile storage fromTile = map[fromRow][fromCol];
        Tile storage toTile = map[toRow][toCol];

        require(fromTile.occupant == msg.sender, "Not your units");
        require(toTile.occupant == msg.sender || toTile.occupant == address(0), "Tile occupied by another player");

        for (uint256 i = 0; i < unitsToMove.length; i++) {
            uint16 unitId = unitsToMove[i].unitId;
            uint16 amount = unitsToMove[i].amount;

            bool foundFromUnit = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == unitId) {
                    require(amount <= fromTile.units[j].amount, "Not enough units");
                    fromTile.units[j].amount -= amount;

                    if (fromTile.units[j].amount == 0) {
                        fromTile.units[j] = fromTile.units[fromTile.units.length - 1];
                        fromTile.units.pop();
                    }

                    foundFromUnit = true;
                    break;
                }
            }
            require(foundFromUnit, "Unit not found in fromTile");

            bool foundToUnit = false;
            for (uint256 j = 0; j < toTile.units.length; j++) {
                if (toTile.units[j].unitId == unitId) {
                    toTile.units[j].amount += amount;
                    foundToUnit = true;
                    break;
                }
            }

            if (!foundToUnit) {
                toTile.units.push(UnitAmount({unitId: unitId, amount: amount}));
            }
        }

        uint16 totalUnitsInToTile = 0;
        for (uint256 i = 0; i < toTile.units.length; i++) {
            totalUnitsInToTile += toTile.units[i].amount;
        }
        require(totalUnitsInToTile <= maxUnitsPerTile, "Exceeds max units per tile");

        if (toTile.occupant == address(0) && toTile.units.length > 0) {
            toTile.occupant = msg.sender;
        }
        if (fromTile.units.length == 0) {
            fromTile.occupant = address(0);
        }

        emit UnitsMoved(fromRow, fromCol, toRow, toCol, unitsToMove);
    }

    function attack(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol) external nonReentrant {
        require(fromRow < mapRows && fromCol < mapCols, "Invalid from coordinates");
        require(toRow < mapRows && toCol < mapCols, "Invalid to coordinates");

        uint16 distance = calculateDistance(fromRow, fromCol, toRow, toCol);
        require(distance <= maxUnitMovementRange, "Movement range exceeded");

        Tile storage fromTile = map[fromRow][fromCol];
        Tile storage toTile = map[toRow][toCol];

        require(fromTile.occupant == msg.sender, "Not your units");
        require(toTile.occupant != msg.sender && toTile.occupant != address(0), "Invalid target");
        require(fromTile.units.length > 0 && toTile.units.length > 0, "No units to attack");

        (
            bool attackerWins,
            UnitAmount[] memory survivingAttackerUnits,
            UnitAmount[] memory survivingDefenderUnits
        ) = simulateBattle(fromTile.units, toTile.units);

        address defender = toTile.occupant;

        if (attackerWins) {
            Loot[] memory lootERC20;
            Loot1155[] memory lootERC1155;
            (lootERC20, lootERC1155) = calculateLoot(toTile, toTile.units, survivingDefenderUnits);

            distributeLoot(lootERC20, lootERC1155, msg.sender);

            delete toTile.units;
            for (uint256 i = 0; i < survivingAttackerUnits.length; i++) {
                toTile.units.push(survivingAttackerUnits[i]);
            }
            toTile.occupant = msg.sender;
            toTile.buildingId = 0;

            delete fromTile.units;
            fromTile.occupant = address(0);
        } else {
            delete fromTile.units;
            fromTile.occupant = address(0);

            delete toTile.units;
            for (uint256 i = 0; i < survivingDefenderUnits.length; i++) {
                toTile.units.push(survivingDefenderUnits[i]);
            }
        }

        emit AttackResult(msg.sender, defender, fromRow, fromCol, toRow, toCol, attackerWins);
    }

    struct UnitStats {
        uint16 unitId;
        uint256 totalHP;
        uint256 totalDamage;
    }

    function simulateBattle(
        UnitAmount[] storage attackerUnits,
        UnitAmount[] storage defenderUnits
    )
        internal
        view
        returns (
            bool attackerWins,
            UnitAmount[] memory survivingAttackerUnits,
            UnitAmount[] memory survivingDefenderUnits
        )
    {
        uint256 attackerTotalHP = 0;
        uint256 defenderTotalHP = 0;

        UnitStats[] memory attackerUnitStats = new UnitStats[](attackerUnits.length);
        for (uint256 i = 0; i < attackerUnits.length; i++) {
            uint16 unitId = attackerUnits[i].unitId;
            uint16 amount = attackerUnits[i].amount;

            IUnitManager.Unit memory unit = unitManager.getUnit(unitId);

            uint256 unitTotalHP = uint256(unit.hp) * amount;
            uint256 unitTotalDamage = uint256(unit.damage) * amount;

            attackerUnitStats[i] = UnitStats({unitId: unitId, totalHP: unitTotalHP, totalDamage: unitTotalDamage});

            attackerTotalHP += unitTotalHP;
        }

        UnitStats[] memory defenderUnitStats = new UnitStats[](defenderUnits.length);
        for (uint256 i = 0; i < defenderUnits.length; i++) {
            uint16 unitId = defenderUnits[i].unitId;
            uint16 amount = defenderUnits[i].amount;

            IUnitManager.Unit memory unit = unitManager.getUnit(unitId);

            uint256 unitTotalHP = uint256(unit.hp) * amount;
            uint256 unitTotalDamage = uint256(unit.damage) * amount;

            defenderUnitStats[i] = UnitStats({unitId: unitId, totalHP: unitTotalHP, totalDamage: unitTotalDamage});

            defenderTotalHP += unitTotalHP;
        }

        uint256 totalAttackerDamage = 0;
        for (uint256 i = 0; i < attackerUnitStats.length; i++) {
            totalAttackerDamage += attackerUnitStats[i].totalDamage;
        }

        uint256 totalDefenderDamage = 0;
        for (uint256 i = 0; i < defenderUnitStats.length; i++) {
            totalDefenderDamage += defenderUnitStats[i].totalDamage;
        }

        uint256 remainingAttackerHP = attackerTotalHP > totalDefenderDamage ? attackerTotalHP - totalDefenderDamage : 0;
        uint256 remainingDefenderHP = defenderTotalHP > totalAttackerDamage ? defenderTotalHP - totalAttackerDamage : 0;

        attackerWins = remainingDefenderHP == 0 && remainingAttackerHP > 0;

        uint256 attackerSurvivalRate = attackerTotalHP > 0 ? (remainingAttackerHP * 1e18) / attackerTotalHP : 0;
        uint256 defenderSurvivalRate = defenderTotalHP > 0 ? (remainingDefenderHP * 1e18) / defenderTotalHP : 0;

        survivingAttackerUnits = calculateSurvivingUnits(attackerUnits, attackerSurvivalRate);
        survivingDefenderUnits = calculateSurvivingUnits(defenderUnits, defenderSurvivalRate);
    }

    function calculateSurvivingUnits(
        UnitAmount[] storage units,
        uint256 survivalRate
    ) internal view returns (UnitAmount[] memory survivingUnits) {
        uint256 count = 0;
        for (uint256 i = 0; i < units.length; i++) {
            uint16 amount = units[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * survivalRate) / 1e18);
            if (survivingAmount > 0) {
                count++;
            }
        }

        survivingUnits = new UnitAmount[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            uint16 unitId = units[i].unitId;
            uint16 amount = units[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * survivalRate) / 1e18);
            if (survivingAmount > 0) {
                survivingUnits[index] = UnitAmount({unitId: unitId, amount: survivingAmount});
                index++;
            }
        }
    }

    struct Loot {
        address resource;
        uint256 amount;
    }

    struct Loot1155 {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    function calculateLoot(
        Tile storage toTile,
        UnitAmount[] storage originalDefenderUnits,
        UnitAmount[] memory survivingDefenderUnits
    ) internal returns (Loot[] memory lootERC20, Loot1155[] memory lootERC1155) {
        uint256 maxLootERC20Size = 100;
        uint256 maxLootERC1155Size = 100;

        Loot[] memory tempLootERC20 = new Loot[](maxLootERC20Size);
        uint256 lootERC20Count = 0;

        Loot1155[] memory tempLootERC1155 = new Loot1155[](maxLootERC1155Size);
        uint256 lootERC1155Count = 0;

        for (uint256 i = 0; i < originalDefenderUnits.length; i++) {
            uint16 unitId = originalDefenderUnits[i].unitId;
            uint16 originalAmount = originalDefenderUnits[i].amount;
            uint16 survivingAmount = 0;

            for (uint256 j = 0; j < survivingDefenderUnits.length; j++) {
                if (survivingDefenderUnits[j].unitId == unitId) {
                    survivingAmount = survivingDefenderUnits[j].amount;
                    break;
                }
            }

            uint16 destroyedAmount = originalAmount - survivingAmount;

            if (destroyedAmount > 0) {
                (lootERC20Count, lootERC1155Count) = collectUnitCosts(
                    unitId,
                    destroyedAmount,
                    tempLootERC20,
                    lootERC20Count,
                    tempLootERC1155,
                    lootERC1155Count
                );
            }
        }

        if (toTile.buildingId != 0) {
            lootERC20Count = collectBuildingCosts(toTile.buildingId, tempLootERC20, lootERC20Count);
        }

        lootERC20 = new Loot[](lootERC20Count);
        for (uint256 i = 0; i < lootERC20Count; i++) {
            lootERC20[i] = tempLootERC20[i];
        }

        lootERC1155 = new Loot1155[](lootERC1155Count);
        for (uint256 i = 0; i < lootERC1155Count; i++) {
            lootERC1155[i] = tempLootERC1155[i];
        }
    }

    function collectUnitCosts(
        uint16 unitId,
        uint256 destroyedAmount,
        Loot[] memory tempLootERC20,
        uint256 lootERC20Count,
        Loot1155[] memory tempLootERC1155,
        uint256 lootERC1155Count
    ) internal returns (uint256, uint256) {
        IUnitManager.Unit memory unit = unitManager.getUnit(unitId);
        IAssetManager.Asset memory asset = assetManager.getAsset(unit.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = unit.trainCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 i = 0; i < resources.length; i++) {
            uint256 totalAmount = costs[i] * destroyedAmount;
            lootERC20Count = addToLootERC20(tempLootERC20, resources[i], totalAmount, lootERC20Count);
        }

        if (unit.upgradeItemId != 0) {
            address itemAddress = asset.item;
            uint256 totalAmount = destroyedAmount;
            lootERC1155Count = addToLootERC1155(
                tempLootERC1155,
                itemAddress,
                unit.upgradeItemId,
                totalAmount,
                lootERC1155Count
            );
        }

        if (unit.preUpgradeUnitId != 0) {
            (lootERC20Count, lootERC1155Count) = collectUnitCosts(
                uint16(unit.preUpgradeUnitId),
                destroyedAmount,
                tempLootERC20,
                lootERC20Count,
                tempLootERC1155,
                lootERC1155Count
            );
        }

        return (lootERC20Count, lootERC1155Count);
    }

    function collectBuildingCosts(
        uint16 buildingId,
        Loot[] memory tempLootERC20,
        uint256 lootERC20Count
    ) internal returns (uint256) {
        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        IAssetManager.Asset memory asset = assetManager.getAsset(building.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = building.constructionCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 i = 0; i < resources.length; i++) {
            uint256 totalAmount = costs[i];
            lootERC20Count = addToLootERC20(tempLootERC20, resources[i], totalAmount, lootERC20Count);
        }

        if (building.preUpgradeBuildingId != 0) {
            lootERC20Count = collectBuildingCosts(uint16(building.preUpgradeBuildingId), tempLootERC20, lootERC20Count);
        }

        return lootERC20Count;
    }

    function addToLootERC20(
        Loot[] memory lootArray,
        address resource,
        uint256 amount,
        uint256 lootCount
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < lootCount; i++) {
            if (lootArray[i].resource == resource) {
                lootArray[i].amount += amount;
                return lootCount;
            }
        }
        require(lootCount < lootArray.length, "ERC20 loot array overflow");
        lootArray[lootCount] = Loot({resource: resource, amount: amount});
        return lootCount + 1;
    }

    function addToLootERC1155(
        Loot1155[] memory lootArray,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 lootCount
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < lootCount; i++) {
            if (lootArray[i].tokenAddress == tokenAddress && lootArray[i].tokenId == tokenId) {
                lootArray[i].amount += amount;
                return lootCount;
            }
        }
        require(lootCount < lootArray.length, "ERC1155 loot array overflow");
        lootArray[lootCount] = Loot1155({tokenAddress: tokenAddress, tokenId: tokenId, amount: amount});
        return lootCount + 1;
    }

    function distributeLoot(Loot[] memory lootERC20, Loot1155[] memory lootERC1155, address attacker) internal {
        for (uint256 i = 0; i < lootERC20.length; i++) {
            uint256 totalAmount = lootERC20[i].amount;

            uint256 ownerShare = (totalAmount * ownerSharePercentage) / 100;
            uint256 attackerShare = totalAmount - ownerShare;

            IERC20 token = IERC20(lootERC20[i].resource);

            require(token.transfer(attacker, attackerShare), "ERC20 transfer to attacker failed");
            require(token.transfer(owner(), ownerShare), "ERC20 transfer to owner failed");
        }

        for (uint256 i = 0; i < lootERC1155.length; i++) {
            uint256 totalAmount = lootERC1155[i].amount;

            uint256 ownerShare = (totalAmount * ownerSharePercentage) / 100;
            uint256 attackerShare = totalAmount - ownerShare;

            IERC1155 token = IERC1155(lootERC1155[i].tokenAddress);

            token.safeTransferFrom(address(this), attacker, lootERC1155[i].tokenId, attackerShare, "");
            token.safeTransferFrom(address(this), owner(), lootERC1155[i].tokenId, ownerShare, "");
        }
    }

    function buildBuilding(uint16 row, uint16 col, uint256 buildingId) external nonReentrant {
        require(row < mapRows && col < mapCols, "Invalid coordinates");

        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);

        Tile storage tile = map[row][col];
        require(tile.occupant == address(0) || tile.occupant == msg.sender, "Tile occupied by another player");
        require(tile.buildingId == 0, "Building already exists on this tile");

        if (building.isHeadquarters) {
            require(!isWithinEnemyBuildingRange(row, col, 3), "Cannot build near enemy building");
        } else {
            require(isWithinPlayerHeadquartersRange(msg.sender, row, col, 7), "Cannot build outside of allowed range");
            require(!isWithinEnemyBuildingRange(row, col, 3), "Cannot build near enemy building");
        }

        deductConstructionCosts(building);

        tile.occupant = msg.sender;
        tile.buildingId = uint16(buildingId);

        emit BuildingConstructed(msg.sender, row, col, buildingId);
    }

    function isWithinEnemyBuildingRange(uint16 row, uint16 col, uint16 range) internal view returns (bool) {
        uint16 startRow = row >= range ? row - range : 0;
        uint16 endRow = row + range < mapRows ? row + range : mapRows - 1;
        uint16 startCol = col >= range ? col - range : 0;
        uint16 endCol = col + range < mapCols ? col + range : mapCols - 1;

        for (uint16 i = startRow; i <= endRow; i++) {
            for (uint16 j = startCol; j <= endCol; j++) {
                uint16 distance = calculateDistance(row, col, i, j);
                if (distance <= range) {
                    Tile storage tile = map[i][j];
                    if (tile.buildingId != 0 && tile.occupant != address(0) && tile.occupant != msg.sender) {
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
        uint16 endRow = row + range < mapRows ? row + range : mapRows - 1;
        uint16 startCol = col >= range ? col - range : 0;
        uint16 endCol = col + range < mapCols ? col + range : mapCols - 1;

        for (uint16 i = startRow; i <= endRow; i++) {
            for (uint16 j = startCol; j <= endCol; j++) {
                Tile storage tile = map[i][j];
                if (tile.occupant == player && tile.buildingId != 0) {
                    IBuildingManager.Building memory building = buildingManager.getBuilding(tile.buildingId);
                    if (building.isHeadquarters) {
                        uint16 allowedRange = 3 + uint16((building.level - 1) * 2);
                        uint16 distance = calculateDistance(i, j, row, col);
                        if (distance <= allowedRange) {
                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    function deductConstructionCosts(IBuildingManager.Building memory building) internal {
        IAssetManager.Asset memory asset = assetManager.getAsset(building.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = building.constructionCosts;

        require(resources.length == costs.length, "Resource and cost length mismatch");

        for (uint256 i = 0; i < resources.length; i++) {
            IERC20 token = IERC20(resources[i]);
            require(token.transferFrom(msg.sender, address(this), costs[i]), "Resource transfer failed");
        }
    }

    function upgradeBuilding(uint16 row, uint16 col, uint256 newBuildingId) external nonReentrant {
        require(row < mapRows && col < mapCols, "Invalid coordinates");

        Tile storage tile = map[row][col];

        require(tile.occupant == msg.sender, "Not your building");
        require(tile.buildingId != 0, "No building on this tile");

        IBuildingManager.Building memory currentBuilding = buildingManager.getBuilding(tile.buildingId);
        IBuildingManager.Building memory upgradedBuilding = buildingManager.getBuilding(newBuildingId);

        require(currentBuilding.level < upgradedBuilding.level, "Invalid upgrade");
        require(currentBuilding.isHeadquarters == upgradedBuilding.isHeadquarters, "Cannot change building type");
        require(upgradedBuilding.preUpgradeBuildingId == tile.buildingId, "Invalid upgrade path");

        deductConstructionCosts(upgradedBuilding);

        tile.buildingId = uint16(newBuildingId);

        emit BuildingConstructed(msg.sender, row, col, newBuildingId);
    }

    function trainUnits(uint16 row, uint16 col, uint16 unitId, uint16 amount) external nonReentrant {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        require(amount > 0, "Amount must be greater than zero");

        Tile storage tile = map[row][col];

        require(tile.occupant == msg.sender, "Not your tile");
        require(tile.buildingId != 0, "No building on this tile");

        bool canProduce = buildingManager.canProduceUnit(tile.buildingId, unitId);
        require(canProduce, "Building cannot produce this unit");

        IUnitManager.Unit memory unitInfo = unitManager.getUnit(unitId);
        require(unitInfo.upgradeItemId == 0, "Unit is not a producible unit");

        IAssetManager.Asset memory asset = assetManager.getAsset(unitInfo.assetVersion);
        address[] memory resources = asset.resources;
        uint256[] memory costs = unitInfo.trainCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 i = 0; i < resources.length; i++) {
            uint256 totalCost = costs[i] * amount;
            IERC20 token = IERC20(resources[i]);
            require(token.transferFrom(msg.sender, address(this), totalCost), "Resource transfer failed");
        }

        bool unitExists = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitId) {
                tile.units[i].amount += amount;
                unitExists = true;
                break;
            }
        }
        if (!unitExists) {
            tile.units.push(UnitAmount({unitId: unitId, amount: amount}));
        }

        uint16 totalUnits = 0;
        for (uint256 i = 0; i < tile.units.length; i++) {
            totalUnits += tile.units[i].amount;
        }
        require(totalUnits <= maxUnitsPerTile, "Exceeds max units per tile");

        emit UnitsTrained(msg.sender, row, col, unitId, amount);
    }

    function upgradeUnits(uint16 row, uint16 col, uint16 unitId, uint16 amount) external nonReentrant {
        require(row < mapRows && col < mapCols, "Invalid coordinates");
        require(amount > 0, "Amount must be greater than zero");

        Tile storage tile = map[row][col];
        require(tile.occupant == msg.sender, "Not your tile");

        IUnitManager.Unit memory unitInfo = unitManager.getUnit(unitId);
        require(unitInfo.preUpgradeUnitId != 0, "Unit cannot be upgraded");

        uint16 preUpgradeUnitId = uint16(unitInfo.preUpgradeUnitId);

        bool found = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == preUpgradeUnitId) {
                require(tile.units[i].amount >= amount, "Not enough units to upgrade");
                tile.units[i].amount -= amount;
                if (tile.units[i].amount == 0) {
                    tile.units[i] = tile.units[tile.units.length - 1];
                    tile.units.pop();
                }
                found = true;
                break;
            }
        }
        require(found, "No units to upgrade");

        uint256 upgradeItemId = unitInfo.upgradeItemId;
        require(upgradeItemId != 0, "No upgrade item required");

        IAssetManager.Asset memory asset = assetManager.getAsset(unitInfo.assetVersion);
        address itemAddress = asset.item;
        IERC1155 itemToken = IERC1155(itemAddress);

        itemToken.safeTransferFrom(msg.sender, address(this), upgradeItemId, amount, "");

        bool unitExists = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitId) {
                tile.units[i].amount += amount;
                unitExists = true;
                break;
            }
        }
        if (!unitExists) {
            tile.units.push(UnitAmount({unitId: unitId, amount: amount}));
        }

        uint16 totalUnits = 0;
        for (uint256 i = 0; i < tile.units.length; i++) {
            totalUnits += tile.units[i].amount;
        }
        require(totalUnits <= maxUnitsPerTile, "Exceeds max units per tile");

        emit UnitsUpgraded(msg.sender, row, col, unitId, amount);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
