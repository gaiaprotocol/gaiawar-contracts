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

        emit AttackResult(msg.sender, toTile.occupant, fromRow, fromCol, toRow, toCol, attackerWins);
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

            IUnitManager.Unit memory unit = unitManager.getUnitStats(unitId);

            uint256 unitTotalHP = uint256(unit.hp) * amount;
            uint256 unitTotalDamage = uint256(unit.damage) * amount;

            attackerUnitStats[i] = UnitStats({unitId: unitId, totalHP: unitTotalHP, totalDamage: unitTotalDamage});

            attackerTotalHP += unitTotalHP;
        }

        UnitStats[] memory defenderUnitStats = new UnitStats[](defenderUnits.length);
        for (uint256 i = 0; i < defenderUnits.length; i++) {
            uint16 unitId = defenderUnits[i].unitId;
            uint16 amount = defenderUnits[i].amount;

            IUnitManager.Unit memory unit = unitManager.getUnitStats(unitId);

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
        mapping(address => uint256) memory lootERC20Mapping;
        mapping(bytes32 => uint256) memory lootERC1155Mapping;

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
                (
                    address[] memory resources,
                    uint256[] memory costs,
                    address[] memory items,
                    uint256[] memory itemIds,
                    uint256[] memory itemAmounts
                ) = unitManager.getUnitTrainCosts(unitId);

                for (uint256 k = 0; k < resources.length; k++) {
                    lootERC20Mapping[resources[k]] += costs[k] * destroyedAmount;
                }

                for (uint256 k = 0; k < items.length; k++) {
                    bytes32 key = keccak256(abi.encodePacked(items[k], itemIds[k]));
                    lootERC1155Mapping[key] += itemAmounts[k] * destroyedAmount;
                }
            }
        }

        if (toTile.buildingId != 0) {
            (
                address[] memory resources,
                uint256[] memory costs,
                address[] memory items,
                uint256[] memory itemIds,
                uint256[] memory itemAmounts
            ) = buildingManager.getBuildingConstructionCosts(toTile.buildingId);

            for (uint256 j = 0; j < resources.length; j++) {
                lootERC20Mapping[resources[j]] += costs[j];
            }

            for (uint256 j = 0; j < items.length; j++) {
                bytes32 key = keccak256(abi.encodePacked(items[j], itemIds[j]));
                lootERC1155Mapping[key] += itemAmounts[j];
            }
        }

        uint256 lootERC20Count = 0;
        address[] memory resourceList = assetManager.getAllResources();
        for (uint256 i = 0; i < resourceList.length; i++) {
            if (lootERC20Mapping[resourceList[i]] > 0) {
                lootERC20Count++;
            }
        }

        lootERC20 = new Loot[](lootERC20Count);
        uint256 index = 0;
        for (uint256 i = 0; i < resourceList.length; i++) {
            address resource = resourceList[i];
            uint256 amount = lootERC20Mapping[resource];
            if (amount > 0) {
                lootERC20[index] = Loot({resource: resource, amount: amount});
                index++;
            }
        }

        uint256 lootERC1155Count = 0;
        bytes32[] memory keys = assetManager.getAllItemKeys();
        for (uint256 i = 0; i < keys.length; i++) {
            if (lootERC1155Mapping[keys[i]] > 0) {
                lootERC1155Count++;
            }
        }

        lootERC1155 = new Loot1155[](lootERC1155Count);
        index = 0;
        for (uint256 i = 0; i < keys.length; i++) {
            uint256 amount = lootERC1155Mapping[keys[i]];
            if (amount > 0) {
                (address tokenAddress, uint256 tokenId) = assetManager.getItemByKey(keys[i]);
                lootERC1155[index] = Loot1155({tokenAddress: tokenAddress, tokenId: tokenId, amount: amount});
                index++;
            }
        }

        return (lootERC20, lootERC1155);
    }

    function distributeLoot(Loot[] memory lootERC20, Loot1155[] memory lootERC1155, address attacker) internal {
        uint256 attackerSharePercentage = 100 - ownerSharePercentage;

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
