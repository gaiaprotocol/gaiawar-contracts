// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IAssetManager.sol";
import "./IBuildingManager.sol";
import "./IUnitManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract GaiaWar is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IAssetManager public assetManager;
    IBuildingManager public buildingManager;
    IUnitManager public unitManager;

    event AssetManagerSet(address indexed newAssetManager);
    event BuildingManagerSet(address indexed newBuildingManager);
    event UnitManagerSet(address indexed newUnitManager);

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

    uint16 public mapRows;
    uint16 public mapCols;

    uint16 public maxUnitsPerTile;
    uint16 public maxUnitMovementRange;

    uint8 public ownerSharePercentage;

    event MapSizeUpdated(uint16 newRows, uint16 newCols);
    event MaxUnitsPerTileUpdated(uint16 newMaxUnits);
    event MaxUnitMovementRangeUpdated(uint16 newMaxRange);
    event OwnerSharePercentageUpdated(uint8 newPercentage);

    function initialize(
        address _assetManager,
        address _buildingManager,
        address _unitManager,
        uint16 _mapRows,
        uint16 _mapCols,
        uint16 _maxUnitsPerTile,
        uint16 _maxUnitMovementRange,
        uint8 _ownerSharePercentage
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        assetManager = IAssetManager(_assetManager);
        buildingManager = IBuildingManager(_buildingManager);
        unitManager = IUnitManager(_unitManager);
        mapRows = _mapRows;
        mapCols = _mapCols;
        maxUnitsPerTile = _maxUnitsPerTile;
        maxUnitMovementRange = _maxUnitMovementRange;
        ownerSharePercentage = _ownerSharePercentage;

        emit AssetManagerSet(_assetManager);
        emit BuildingManagerSet(_buildingManager);
        emit UnitManagerSet(_unitManager);
        emit MapSizeUpdated(_mapRows, _mapCols);
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
        emit MaxUnitMovementRangeUpdated(_maxUnitMovementRange);
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
        require(fromRow < mapRows, "Invalid fromRow");
        require(fromCol < mapCols, "Invalid fromCol");
        require(toRow < mapRows, "Invalid toRow");
        require(toCol < mapCols, "Invalid toCol");

        uint16 distance = calculateDistance(fromRow, fromCol, toRow, toCol);
        require(distance <= maxUnitMovementRange, "Movement range exceeded");

        Tile storage fromTile = map[fromRow][fromCol];
        Tile storage toTile = map[toRow][toCol];

        require(fromTile.occupant == msg.sender, "Not your units");
        require(toTile.occupant == msg.sender || toTile.occupant == address(0), "Not your units");

        for (uint256 i = 0; i < unitsToMove.length; i++) {
            uint16 unitId = unitsToMove[i].unitId;
            uint16 amount = unitsToMove[i].amount;

            bool foundFromUnit = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == unitId) {
                    require(amount <= fromTile.units[j].amount, "Invalid amount");
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
        for (uint256 j = 0; j < toTile.units.length; j++) {
            totalUnitsInToTile += toTile.units[j].amount;
        }

        require(totalUnitsInToTile <= maxUnitsPerTile, "Exceeds max units per tile");

        emit UnitsMoved(fromRow, fromCol, toRow, toCol, unitsToMove);
    }

    function attack(uint16 fromRow, uint16 fromCol, uint16 toRow, uint16 toCol) external nonReentrant {
        require(fromRow < mapRows, "Invalid fromRow");
        require(fromCol < mapCols, "Invalid fromCol");
        require(toRow < mapRows, "Invalid toRow");
        require(toCol < mapCols, "Invalid toCol");

        uint16 distance = calculateDistance(fromRow, fromCol, toRow, toCol);
        require(distance <= maxUnitMovementRange, "Movement range exceeded");

        Tile storage fromTile = map[fromRow][fromCol];
        Tile storage toTile = map[toRow][toCol];

        require(fromTile.occupant == msg.sender, "Not your units");
        require(toTile.occupant != msg.sender, "Cannot attack your own units");
        require(toTile.occupant != address(0), "No enemy units to attack");
        require(fromTile.units.length > 0, "No units to attack with");
        require(toTile.units.length > 0, "No enemy units to attack");

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

            IUnitManager.Unit memory unit = unitManager.units(unitId);

            uint256 unitTotalHP = uint256(unit.hp) * amount;
            uint256 unitTotalDamage = uint256(unit.damage) * amount;

            attackerUnitStats[i] = UnitStats({unitId: unitId, totalHP: unitTotalHP, totalDamage: unitTotalDamage});

            attackerTotalHP += unitTotalHP;
        }

        UnitStats[] memory defenderUnitStats = new UnitStats[](defenderUnits.length);
        for (uint256 i = 0; i < defenderUnits.length; i++) {
            uint16 unitId = defenderUnits[i].unitId;
            uint16 amount = defenderUnits[i].amount;

            IUnitManager.Unit memory unit = unitManager.units(unitId);

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

        uint256 survivingAttackerCount = 0;
        for (uint256 i = 0; i < attackerUnits.length; i++) {
            uint16 amount = attackerUnits[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * attackerSurvivalRate) / 1e18);
            if (survivingAmount > 0) {
                survivingAttackerCount++;
            }
        }

        survivingAttackerUnits = new UnitAmount[](survivingAttackerCount);
        uint256 index = 0;
        for (uint256 i = 0; i < attackerUnits.length; i++) {
            uint16 unitId = attackerUnits[i].unitId;
            uint16 amount = attackerUnits[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * attackerSurvivalRate) / 1e18);

            if (survivingAmount > 0) {
                survivingAttackerUnits[index] = UnitAmount({unitId: unitId, amount: survivingAmount});
                index++;
            }
        }

        uint256 survivingDefenderCount = 0;
        for (uint256 i = 0; i < defenderUnits.length; i++) {
            uint16 amount = defenderUnits[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * defenderSurvivalRate) / 1e18);
            if (survivingAmount > 0) {
                survivingDefenderCount++;
            }
        }

        survivingDefenderUnits = new UnitAmount[](survivingDefenderCount);
        index = 0;
        for (uint256 i = 0; i < defenderUnits.length; i++) {
            uint16 unitId = defenderUnits[i].unitId;
            uint16 amount = defenderUnits[i].amount;
            uint16 survivingAmount = uint16((uint256(amount) * defenderSurvivalRate) / 1e18);

            if (survivingAmount > 0) {
                survivingDefenderUnits[index] = UnitAmount({unitId: unitId, amount: survivingAmount});
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

    function collectUnitCosts(
        uint16 unitId,
        uint256 destroyedAmount,
        Loot[] memory tempLootERC20,
        uint256 lootERC20Count,
        Loot1155[] memory tempLootERC1155,
        uint256 lootERC1155Count
    ) internal returns (uint256, uint256) {
        IUnitManager.Unit memory unit = unitManager.units(unitId);
        IAssetManager.Asset memory asset = assetManager.assets(unit.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = unit.trainCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 k = 0; k < resources.length; k++) {
            uint256 totalAmount = costs[k] * destroyedAmount;
            lootERC20Count = addToLootERC20(tempLootERC20, resources[k], totalAmount, lootERC20Count);
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
        IBuildingManager.Building memory building = buildingManager.buildings(buildingId);
        IAssetManager.Asset memory asset = assetManager.assets(building.assetVersion);

        address[] memory resources = asset.resources;
        uint256[] memory costs = building.constructionCosts;

        require(resources.length == costs.length, "Mismatch in resources and costs length");

        for (uint256 k = 0; k < resources.length; k++) {
            uint256 totalAmount = costs[k];
            lootERC20Count = addToLootERC20(tempLootERC20, resources[k], totalAmount, lootERC20Count);
        }

        if (building.preUpgradeBuildingId != 0) {
            lootERC20Count = collectBuildingCosts(uint16(building.preUpgradeBuildingId), tempLootERC20, lootERC20Count);
        }

        return lootERC20Count;
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
}
