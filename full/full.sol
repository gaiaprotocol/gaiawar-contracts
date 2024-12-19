// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.28;

  

contract Battleground is OperatorManagement, IBattleground {
    uint16 public override width;
    uint16 public override height;
    uint16 public maxUnitsPerTile;

    ILootVault public lootVault;
    IBuildingManager public buildingManager;

    mapping(int16 => mapping(int16 => Tile)) public tiles;
    mapping(address => Coordinates[]) public playerHeadquarters;

    event TileUpdated(Coordinates coordinates, Tile tile);

    function initialize(uint16 _width, uint16 _height) external initializer {
        __Ownable_init(msg.sender);

        width = _width;
        height = _height;
    }

    function updateDimensions(uint16 _width, uint16 _height) external onlyOwner {
        require(_width > 0, "Width must be greater than 0");
        require(_height > 0, "Height must be greater than 0");

        width = _width;
        height = _height;
    }

    function updateMaxUnitsPerTile(uint16 _maxUnitsPerTile) external onlyOwner {
        require(_maxUnitsPerTile > 0, "Max units per tile must be greater than 0");

        maxUnitsPerTile = _maxUnitsPerTile;
    }

    function updateLootVault(address _lootVault) external onlyOwner {
        lootVault = ILootVault(_lootVault);
    }

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }

    function getTile(Coordinates memory coordinates) external view returns (Tile memory) {
        return tiles[coordinates.x][coordinates.y];
    }

    function hasHeadquarters(address player) external view returns (bool) {
        return playerHeadquarters[player].length > 0;
    }

    modifier validCoordinates(Coordinates memory coordinates) {
        int16 minX = -int16(width / 2);
        int16 maxX = int16(width / 2 - 1);
        int16 minY = -int16(height / 2);
        int16 maxY = int16(height / 2 - 1);
        require(coordinates.x >= minX && coordinates.x <= maxX, "Invalid x coordinate");
        require(coordinates.y >= minY && coordinates.y <= maxY, "Invalid y coordinate");
        _;
    }

    function _addHQCoordinate(address player, Coordinates memory coordinates) private {
        playerHeadquarters[player].push(coordinates);
    }

    function _removeHQCoordinate(address player, Coordinates memory coordinates) private {
        Coordinates[] storage playerHQs = playerHeadquarters[player];
        uint256 length = playerHQs.length;

        for (uint256 i = 0; i < length; i++) {
            if (playerHQs[i].x == coordinates.x && playerHQs[i].y == coordinates.y) {
                playerHQs[i] = playerHQs[length - 1];
                playerHQs.pop();
                break;
            }
        }
    }

    function updateTile(
        Coordinates memory coordinates,
        Tile memory tile
    ) external override onlyOperator validCoordinates(coordinates) {
        uint16 totalUnits = 0;
        for (uint256 i = 0; i < tile.units.length; i++) {
            totalUnits += tile.units[i].quantity;
        }
        require(totalUnits <= maxUnitsPerTile, "Too many units on tile");

        Tile memory existingTile = tiles[coordinates.x][coordinates.y];
        IBuildingManager.Building memory existingBuilding = buildingManager.getBuilding(existingTile.buildingId);

        tiles[coordinates.x][coordinates.y] = tile;
        IBuildingManager.Building memory building = buildingManager.getBuilding(tile.buildingId);

        if (existingTile.occupant != address(0) && existingBuilding.isHeadquarters) {
            if (existingTile.occupant != tile.occupant || !building.isHeadquarters) {
                _removeHQCoordinate(existingTile.occupant, coordinates);
            }
            if (existingTile.occupant != tile.occupant && building.isHeadquarters) {
                _addHQCoordinate(tile.occupant, coordinates);
            }
        } else if (building.isHeadquarters) {
            _addHQCoordinate(tile.occupant, coordinates);
        }

        emit TileUpdated(coordinates, tile);
    }

    function collectLoot(Coordinates memory coordinates) external {
        Tile storage tile = tiles[coordinates.x][coordinates.y];
        require(tile.occupant == msg.sender, "You do not own this tile");

        lootVault.transferLoot(msg.sender, tile.loot);
        tile.loot = new TokenAmountOperations.TokenAmount[](0);
    }
}



interface IBattleground {
    struct Coordinates {
        int16 x;
        int16 y;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitQuantityOperations.UnitQuantity[] units;
        TokenAmountOperations.TokenAmount[] loot;
    }

    function width() external view returns (uint16);

    function height() external view returns (uint16);

    function getTile(Coordinates memory coordinates) external view returns (Tile memory);

    function hasHeadquarters(address player) external view returns (bool);

    function updateTile(Coordinates memory coordinates, Tile memory tile) external;
}


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILootVault {
    function transferLoot(address recipient, TokenAmountOperations.TokenAmount[] memory loot) external;
}



contract LootVault is OperatorManagement, ILootVault {
    address public protocolFeeRecipient;
    uint256 public protocolFeeRate;

    event LootTransferred(
        address indexed sender,
        address indexed recipient,
        TokenAmountOperations.TokenAmount[] root,
        uint256 protocolFeeRate
    );

    function initialize(address _protocolFeeRecipient, uint256 _protocolFeeRate) external initializer {
        __Ownable_init(msg.sender);

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
    }

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function updateProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
        protocolFeeRate = _protocolFeeRate;
    }

    function transferLoot(
        address recipient,
        TokenAmountOperations.TokenAmount[] memory loot
    ) external override onlyOperator {
        require(recipient != address(0), "Invalid recipient address");
        require(loot.length > 0, "No loot to transfer");

        for (uint256 i = 0; i < loot.length; i++) {
            uint256 amount = loot[i].amount;
            require(amount > 0, "Invalid loot amount");

            if (loot[i].tokenType == TokenAmountOperations.TokenType.ERC20) {
                uint256 protocolFee = (amount * protocolFeeRate) / 1 ether;
                uint256 recipientAmount = amount - protocolFee;
                require(
                    IERC20(loot[i].tokenAddress).transferFrom(address(this), recipient, recipientAmount),
                    "Token transfer failed"
                );
                require(
                    IERC20(loot[i].tokenAddress).transferFrom(address(this), protocolFeeRecipient, protocolFee),
                    "Token transfer failed"
                );
            } else if (loot[i].tokenType == TokenAmountOperations.TokenType.ERC1155) {
                IERC1155(loot[i].tokenAddress).safeTransferFrom(
                    address(this),
                    recipient,
                    loot[i].tokenId,
                    loot[i].amount,
                    ""
                );
            }
        }

        emit LootTransferred(msg.sender, recipient, loot, protocolFeeRate);
    }
}


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OperatorManagement is OwnableUpgradeable {
    mapping(address => bool) public operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        require(!operators[operator], "Already an operator");

        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(operators[operator], "Not an operator");

        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Not an operator");
        _;
    }
}


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BuildingManager is OwnableUpgradeable, IBuildingManager {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    uint16 public nextBuildingId;
    mapping(uint16 => Building) public buildings;

    function initialize() external initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function addBuilding(Building calldata building) external onlyOwner {
        require(building.prerequisiteBuildingId < nextBuildingId, "Previous building does not exist");
        require(building.constructionCost.length > 0, "Construction cost must be provided");

        uint16 buildingId = nextBuildingId;
        nextBuildingId += 1;

        buildings[buildingId] = building;
    }

    function setConstructability(uint16 buildingId, bool canBeConstructed) external onlyOwner {
        require(buildingId < nextBuildingId, "Building does not exist");

        buildings[buildingId].canBeConstructed = canBeConstructed;
    }

    function getBuilding(uint16 buildingId) external view override returns (Building memory) {
        return buildings[buildingId];
    }

    function getTotalBuildingConstructionCost(
        uint16 buildingId
    ) public view override returns (TokenAmountOperations.TokenAmount[] memory) {
        IBuildingManager.Building memory building = buildings[buildingId];
        if (buildings[buildingId].prerequisiteBuildingId == 0) {
            return building.constructionCost;
        } else {
            return
                building.constructionCost.merge(
                    getTotalBuildingConstructionCost(buildings[buildingId].prerequisiteBuildingId)
                );
        }
    }
}


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBuildingManager {
    struct Building {
        uint16 prerequisiteBuildingId;
        bool isHeadquarters;
        uint16 constructionRange;
        uint256 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountOperations.TokenAmount[] constructionCost;
        bool canBeConstructed;
    }

    function getBuilding(uint16 buildingId) external view returns (Building memory);

    function getTotalBuildingConstructionCost(
        uint16 buildingId
    ) external view returns (TokenAmountOperations.TokenAmount[] memory);
}


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUnitManager {
    struct Unit {
        uint16 prerequisiteUnitId;
        uint16[] trainingBuildingIds;
        uint16 healthPoints;
        uint16 attackDamage;
        uint8 attackRange;
        uint8 movementRange;
        uint16 damageBoostPercentage; // 1-10000 (0.01% - 100%)
        TokenAmountOperations.TokenAmount[] trainingCost;
        TokenAmountOperations.TokenAmount[] rangedAttackCost;
        bool canBeTrained;
    }

    function getUnit(uint16 unitId) external view returns (Unit memory);

    function getTotalUnitTrainingCost(uint16 unitId) external view returns (TokenAmountOperations.TokenAmount[] memory);
}


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UnitManager is OwnableUpgradeable, IUnitManager {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    uint16 public nextUnitId;
    mapping(uint16 => Unit) public units;

    function initialize() external initializer {
        __Ownable_init(msg.sender);

        nextUnitId = 1;
    }

    function addUnit(Unit calldata unit) external onlyOwner {
        require(unit.trainingBuildingIds.length > 0, "Training building IDs must be provided");
        for (uint256 i = 0; i < unit.trainingBuildingIds.length; i++) {
            require(unit.trainingBuildingIds[i] > 0, "Training building IDs must be valid");
        }

        require(unit.healthPoints > 0, "Health points must be greater than 0");
        require(unit.trainingCost.length > 0, "Training cost must be provided");

        uint16 unitId = nextUnitId;
        nextUnitId += 1;

        units[unitId] = unit;
    }

    function setTrainability(uint16 unitId, bool canBeTrained) external onlyOwner {
        require(unitId < nextUnitId, "Unit does not exist");

        units[unitId].canBeTrained = canBeTrained;
    }

    function getUnit(uint16 unitId) external view override returns (Unit memory) {
        return units[unitId];
    }

    function getTotalUnitTrainingCost(
        uint16 unitId
    ) public view override returns (TokenAmountOperations.TokenAmount[] memory) {
        IUnitManager.Unit memory unit = units[unitId];
        if (units[unitId].prerequisiteUnitId == 0) {
            return unit.trainingCost;
        } else {
            return unit.trainingCost.merge(getTotalUnitTrainingCost(units[unitId].prerequisiteUnitId));
        }
    }
}



library CoordinatesOperations {
    function manhattanDistance(
        IBattleground.Coordinates memory a,
        IBattleground.Coordinates memory b
    ) internal pure returns (uint16) {
        return uint16((a.x > b.x ? a.x - b.x : b.x - a.x) + (a.y > b.y ? a.y - b.y : b.y - a.y));
    }
}


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TokenAmountOperations {
    enum TokenType {
        ERC20,
        ERC1155
    }

    struct TokenAmount {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    function transferAll(TokenAmount[] memory tokenAmounts, address from, address to) internal {
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            if (tokenAmounts[i].tokenType == TokenType.ERC20) {
                require(
                    IERC20(tokenAmounts[i].tokenAddress).transferFrom(from, to, tokenAmounts[i].amount),
                    "Token transfer failed"
                );
            } else if (tokenAmounts[i].tokenType == TokenType.ERC1155) {
                IERC1155(tokenAmounts[i].tokenAddress).safeTransferFrom(
                    from,
                    to,
                    tokenAmounts[i].tokenId,
                    tokenAmounts[i].amount,
                    ""
                );
            }
        }
    }

    function merge(TokenAmount[] memory a, TokenAmount[] memory b) internal pure returns (TokenAmount[] memory) {
        TokenAmount[] memory result = new TokenAmount[](a.length + b.length);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            result[index] = a[i];
            index++;
        }

        for (uint256 i = 0; i < b.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < result.length; j++) {
                if (result[j].tokenAddress == b[i].tokenAddress && result[j].tokenId == b[i].tokenId) {
                    result[j].amount += b[i].amount;
                    found = true;
                    break;
                }
            }

            if (!found) {
                result[index] = b[i];
                index++;
            }
        }

        assembly {
            mstore(result, index)
        }

        return result;
    }
}


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UnitQuantityOperations {
    struct UnitQuantity {
        uint16 unitId;
        uint16 quantity;
    }

    function subtract(
        UnitQuantity[] memory a,
        UnitQuantity[] memory b
    ) internal pure returns (UnitQuantity[] memory result) {
        uint256 resultLength = 0;

        for (uint256 i = 0; i < a.length; i++) {
            for (uint256 j = 0; j < b.length; j++) {
                if (a[i].unitId == b[j].unitId) {
                    require(a[i].quantity >= b[j].quantity, "Not enough units to subtract");
                    a[i].quantity -= b[j].quantity;
                    break;
                }
            }

            if (a[i].quantity > 0) {
                resultLength++;
            }
        }

        result = new UnitQuantity[](resultLength);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i].quantity > 0) {
                result[index] = a[i];
                index++;
            }
        }
    }

    function merge(UnitQuantity[] memory a, UnitQuantity[] memory b) internal pure returns (UnitQuantity[] memory) {
        UnitQuantity[] memory result = new UnitQuantity[](a.length + b.length);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            result[index] = a[i];
            index++;
        }

        for (uint256 i = 0; i < b.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < result.length; j++) {
                if (result[j].unitId == b[i].unitId) {
                    result[j].quantity += b[i].quantity;
                    found = true;
                    break;
                }
            }

            if (!found) {
                result[index] = b[i];
                index++;
            }
        }

        assembly {
            mstore(result, index)
        }

        return result;
    }
}



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



contract Move is UnitCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using UnitQuantityOperations for UnitQuantityOperations.UnitQuantity[];

    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }

    function move(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityOperations.UnitQuantity[] memory units
    ) external onlyOwner {
        require(units.length > 0, "No units to move");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are moving from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(toTile.occupant == address(0) || toTile.occupant == msg.sender, "You cannot move to an occupied tile");

        uint16 distance = from.manhattanDistance(to);

        for (uint256 i = 0; i < units.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == units[i].unitId) {
                    require(fromTile.units[j].quantity >= units[i].quantity, "Not enough units to move");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            require(distance <= unit.movementRange, "Unit cannot move that far");
        }

        fromTile.units = fromTile.units.subtract(units);
        if (fromTile.units.length == 0) {
            fromTile.occupant = address(0);
        }
        battleground.updateTile(from, fromTile);

        toTile.units = toTile.units.merge(units);
        toTile.occupant = msg.sender;
        battleground.updateTile(to, toTile);
    }
}



contract MoveAndAttack is AttackCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using UnitQuantityOperations for UnitQuantityOperations.UnitQuantity[];
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(
        address _battleground,
        address _lootVault,
        address _unitManager,
        address _buildingManager
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function moveAndAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityOperations.UnitQuantity[] memory attackerUnits
    ) external onlyOwner {
        require(attackerUnits.length > 0, "No units to attack with");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are attacking from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(
            toTile.occupant != address(0) && toTile.occupant != msg.sender,
            "You cannot attack an empty tile or your own tile"
        );

        uint16 distance = from.manhattanDistance(to);

        for (uint256 i = 0; i < attackerUnits.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == attackerUnits[i].unitId) {
                    require(fromTile.units[j].quantity >= attackerUnits[i].quantity, "Not enough units to attack with");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            IUnitManager.Unit memory unit = unitManager.getUnit(attackerUnits[i].unitId);
            require(distance <= unit.movementRange, "Unit cannot move that far");
        }

        fromTile.units = fromTile.units.subtract(attackerUnits);
        if (fromTile.units.length == 0) {
            fromTile.occupant = address(0);
        }
        battleground.updateTile(from, fromTile);

        UnitQuantityOperations.UnitQuantity[] memory defenderUnits = toTile.units;
        TokenAmountOperations.TokenAmount[] memory totalLoot = toTile.loot;

        bool toFinish = false;
        while (true) {
            uint256 attackerDamage = toFinish ? type(uint256).max : 0;
            if (!toFinish) {
                for (uint256 i = 0; i < attackerUnits.length; i++) {
                    IUnitManager.Unit memory unit = unitManager.getUnit(attackerUnits[i].unitId);
                    attackerDamage += uint256(unit.attackDamage) * uint256(attackerUnits[i].quantity);
                }
                attackerDamage = (attackerDamage * 10000) / (10000 + getDamageBoostPercentage(0, attackerUnits));
            }

            uint256 defenderDamage = toFinish ? type(uint256).max : 0;
            if (!toFinish) {
                for (uint256 i = 0; i < toTile.units.length; i++) {
                    IUnitManager.Unit memory unit = unitManager.getUnit(toTile.units[i].unitId);
                    defenderDamage += uint256(unit.attackDamage) * uint256(toTile.units[i].quantity);
                }
                defenderDamage =
                    (defenderDamage * 10000) /
                    (10000 + getDamageBoostPercentage(toTile.buildingId, defenderUnits));
            }

            (
                UnitQuantityOperations.UnitQuantity[] memory remainingDefenderUnits,
                uint256 remainingAttackerDamage,
                TokenAmountOperations.TokenAmount[] memory attackerLoot
            ) = applyDamageToUnits(defenderUnits, attackerDamage);

            (
                UnitQuantityOperations.UnitQuantity[] memory remainingAttackerUnits,
                uint256 remainingDefenderDamage,
                TokenAmountOperations.TokenAmount[] memory defenderLoot
            ) = applyDamageToUnits(attackerUnits, defenderDamage);

            totalLoot = totalLoot.merge(attackerLoot).merge(defenderLoot);

            // Attacker wins
            if (remainingAttackerUnits.length > 0 && remainingDefenderUnits.length == 0) {
                toTile.occupant = msg.sender;
                toTile.units = remainingAttackerUnits;

                if (toTile.buildingId == 0) {
                    lootVault.transferLoot(msg.sender, totalLoot);
                } else {
                    TokenAmountOperations.TokenAmount[] memory constructionCost = buildingManager
                        .getTotalBuildingConstructionCost(toTile.buildingId);
                    toTile.buildingId = 0;
                    lootVault.transferLoot(msg.sender, totalLoot.merge(constructionCost));
                }

                toTile.loot = new TokenAmountOperations.TokenAmount[](0);

                battleground.updateTile(to, toTile);
                break;
            }
            // Defender wins
            else if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length > 0) {
                toTile.units = remainingDefenderUnits;
                toTile.loot = totalLoot;

                battleground.updateTile(to, toTile);
                break;
            }
            // Draw
            else if (remainingAttackerUnits.length == 0 && remainingDefenderUnits.length == 0) {
                toTile.occupant = address(0);
                toTile.units = new UnitQuantityOperations.UnitQuantity[](0);

                if (toTile.buildingId == 0) {
                    toTile.loot = totalLoot;
                } else {
                    TokenAmountOperations.TokenAmount[] memory constructionCost = buildingManager
                        .getTotalBuildingConstructionCost(toTile.buildingId);
                    toTile.buildingId = 0;
                    toTile.loot = totalLoot.merge(constructionCost);
                }

                battleground.updateTile(to, toTile);
                break;
            }
            // Never reached
            else if (attackerDamage == remainingDefenderDamage && defenderDamage == remainingAttackerDamage) {
                require(!toFinish, "Infinite loop detected");
                toFinish = true;
            }
            // Continue
            else {
                attackerUnits = remainingAttackerUnits;
                defenderUnits = remainingDefenderUnits;
            }
        }
    }
}



contract RangedAttack is AttackCommand {
    using CoordinatesOperations for IBattleground.Coordinates;
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(
        address _battleground,
        address _lootVault,
        address _unitManager,
        address _buildingManager
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function rangedAttack(
        IBattleground.Coordinates memory from,
        IBattleground.Coordinates memory to,
        UnitQuantityOperations.UnitQuantity[] memory attackerUnits
    ) external onlyOwner {
        require(attackerUnits.length > 0, "No units to attack with");

        IBattleground.Tile memory fromTile = battleground.getTile(from);
        require(fromTile.occupant == msg.sender, "You do not own the tile you are attacking from");

        IBattleground.Tile memory toTile = battleground.getTile(to);
        require(
            toTile.occupant != address(0) && toTile.occupant != msg.sender,
            "You cannot attack an empty tile or your own tile"
        );

        uint16 distance = from.manhattanDistance(to);

        uint256 attackerDamage = 0;
        TokenAmountOperations.TokenAmount[] memory totalAttackCost;

        for (uint256 i = 0; i < attackerUnits.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < fromTile.units.length; j++) {
                if (fromTile.units[j].unitId == attackerUnits[i].unitId) {
                    require(fromTile.units[j].quantity >= attackerUnits[i].quantity, "Not enough units to attack with");
                    found = true;
                    break;
                }
            }
            require(found, "Unit not found in source tile");

            IUnitManager.Unit memory unit = unitManager.getUnit(attackerUnits[i].unitId);
            require(unit.attackRange >= distance, "Unit cannot attack that far");

            attackerDamage += unit.attackDamage * attackerUnits[i].quantity;

            TokenAmountOperations.TokenAmount[] memory attackCost = unit.rangedAttackCost;
            for (uint256 k = 0; k < attackCost.length; k++) {
                attackCost[k].amount *= attackerUnits[i].quantity;
            }

            totalAttackCost = totalAttackCost.merge(attackCost);
        }

        totalAttackCost.transferAll(msg.sender, address(lootVault));

        (
            UnitQuantityOperations.UnitQuantity[] memory remainingUnits,
            ,
            TokenAmountOperations.TokenAmount[] memory defenderLoot
        ) = applyDamageToUnits(
                toTile.units,
                (attackerDamage * 10000) / (10000 + getDamageBoostPercentage(fromTile.buildingId, attackerUnits))
            );

        if (remainingUnits.length == 0) {
            toTile.occupant = address(0);
            toTile.units = new UnitQuantityOperations.UnitQuantity[](0);

            if (toTile.buildingId == 0) {
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
            } else {
                TokenAmountOperations.TokenAmount[] memory constructionCost = buildingManager
                    .getTotalBuildingConstructionCost(toTile.buildingId);
                toTile.buildingId = 0;
                toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost).merge(constructionCost);
            }
        } else {
            toTile.units = remainingUnits;
            toTile.loot = toTile.loot.merge(defenderLoot).merge(totalAttackCost);
        }

        battleground.updateTile(to, toTile);
    }
}



contract Train is UnitCommand {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }

    function train(
        IBattleground.Coordinates memory coordinates,
        UnitQuantityOperations.UnitQuantity memory unitQuantity
    ) external {
        require(unitQuantity.quantity > 0, "Quantity must be greater than 0");

        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Not the tile owner");

        IUnitManager.Unit memory unit = unitManager.getUnit(unitQuantity.unitId);
        require(unit.canBeTrained && unit.prerequisiteUnitId == 0, "Unit can't be trained");

        bool foundTrainingBuilding = false;
        for (uint256 i = 0; i < unit.trainingBuildingIds.length; i++) {
            if (tile.buildingId == unit.trainingBuildingIds[i]) {
                foundTrainingBuilding = true;
                break;
            }
        }

        require(foundTrainingBuilding, "Unit can't be trained");

        TokenAmountOperations.TokenAmount[] memory cost = unit.trainingCost;
        for (uint256 i = 0; i < unit.trainingCost.length; i++) {
            cost[i].amount *= unitQuantity.quantity;
        }
        cost.transferAll(msg.sender, address(lootVault));

        bool foundSameUnit = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitQuantity.unitId) {
                tile.units[i].quantity += unitQuantity.quantity;
                foundSameUnit = true;
            }
        }

        if (!foundSameUnit) {
            UnitQuantityOperations.UnitQuantity[] memory newUnits = new UnitQuantityOperations.UnitQuantity[](
                tile.units.length + 1
            );
            for (uint256 i = 0; i < tile.units.length; i++) {
                newUnits[i] = tile.units[i];
            }
            newUnits[tile.units.length] = unitQuantity;
            tile.units = newUnits;
        }

        battleground.updateTile(coordinates, tile);
    }
}



contract UpgradeBuilding is BuildingCommand {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(address _battleground, address _lootVault, address _buildingManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
    }

    function upgradeBuilding(IBattleground.Coordinates memory coordinates, uint16 buildingId) external {
        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Only tile occupant can upgrade building");

        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        require(
            building.canBeConstructed && building.prerequisiteBuildingId == tile.buildingId,
            "Building upgrade not allowed"
        );

        TokenAmountOperations.TokenAmount[] memory cost = building.constructionCost;
        cost.transferAll(msg.sender, address(lootVault));

        tile.buildingId = buildingId;
        battleground.updateTile(coordinates, tile);
    }
}



contract UpgradeUnit is UnitCommand {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    function initialize(address _battleground, address _lootVault, address _unitManager) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        unitManager = IUnitManager(_unitManager);
    }

    function upgradeUnit(
        IBattleground.Coordinates memory coordinates,
        UnitQuantityOperations.UnitQuantity memory unitQuantity
    ) external {
        require(unitQuantity.quantity > 0, "Quantity must be greater than 0");

        IBattleground.Tile memory tile = battleground.getTile(coordinates);
        require(tile.occupant == msg.sender, "Not the tile owner");

        IUnitManager.Unit memory unit = unitManager.getUnit(unitQuantity.unitId);
        require(unit.canBeTrained, "Unit can't be trained");

        bool foundPrerequisiteUnit = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unit.prerequisiteUnitId) {
                require(tile.units[i].quantity >= unitQuantity.quantity, "Not enough units to upgrade with");
                tile.units[i].quantity -= unitQuantity.quantity;
                foundPrerequisiteUnit = true;
                break;
            }
        }
        require(foundPrerequisiteUnit, "Prerequisite unit not found");

        TokenAmountOperations.TokenAmount[] memory cost = unit.trainingCost;
        for (uint256 i = 0; i < unit.trainingCost.length; i++) {
            cost[i].amount *= unitQuantity.quantity;
        }
        cost.transferAll(msg.sender, address(lootVault));

        bool foundSameUnit = false;
        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitQuantity.unitId) {
                tile.units[i].quantity += unitQuantity.quantity;
                foundSameUnit = true;
            }
        }

        if (!foundSameUnit) {
            UnitQuantityOperations.UnitQuantity[] memory newUnits = new UnitQuantityOperations.UnitQuantity[](
                tile.units.length + 1
            );
            for (uint256 i = 0; i < tile.units.length; i++) {
                newUnits[i] = tile.units[i];
            }
            newUnits[tile.units.length] = unitQuantity;
            tile.units = newUnits;
        }

        battleground.updateTile(coordinates, tile);
    }
}



abstract contract AttackCommand is UnitCommand {
    using TokenAmountOperations for TokenAmountOperations.TokenAmount[];

    IBuildingManager public buildingManager;

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }

    function getDamageBoostPercentage(
        uint16 buildingId,
        UnitQuantityOperations.UnitQuantity[] memory units
    ) internal view returns (uint256 damageBoostPercentage) {
        IBuildingManager.Building memory building = buildingManager.getBuilding(buildingId);
        damageBoostPercentage = building.damageBoostPercentage;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            if (unit.damageBoostPercentage > 0) {
                damageBoostPercentage += unit.damageBoostPercentage * units[i].quantity;
            }
        }
    }

    function applyDamageToUnits(
        UnitQuantityOperations.UnitQuantity[] memory units,
        uint256 damage
    )
        internal
        view
        returns (
            UnitQuantityOperations.UnitQuantity[] memory remainingUnits,
            uint256 remainingDamage,
            TokenAmountOperations.TokenAmount[] memory loot
        )
    {
        remainingDamage = damage;

        uint256 remainingUnitsLength = 0;

        for (uint256 i = 0; i < units.length; i++) {
            IUnitManager.Unit memory unit = unitManager.getUnit(units[i].unitId);
            uint16 killedUnits = uint16(remainingDamage / unit.healthPoints);

            if (killedUnits == 0) {
                continue;
            }

            if (killedUnits > units[i].quantity) {
                killedUnits = units[i].quantity;
            }

            units[i].quantity -= killedUnits;

            if (units[i].quantity > 0) {
                remainingUnitsLength++;
            }

            remainingDamage -= uint256(killedUnits) * uint256(unit.healthPoints);

            TokenAmountOperations.TokenAmount[] memory trainingCost = unitManager.getTotalUnitTrainingCost(
                units[i].unitId
            );
            for (uint256 j = 0; j < trainingCost.length; j++) {
                trainingCost[j].amount *= killedUnits;
            }

            loot = loot.merge(trainingCost);
        }

        remainingUnits = new UnitQuantityOperations.UnitQuantity[](remainingUnitsLength);

        uint256 index = 0;
        for (uint256 i = 0; i < units.length; i++) {
            if (units[i].quantity > 0) {
                remainingUnits[index] = units[i];
                index++;
            }
        }
    }
}



abstract contract BuildingCommand is Command {
    IBuildingManager public buildingManager;

    function updateBuildingManager(address _buildingManager) external onlyOwner {
        buildingManager = IBuildingManager(_buildingManager);
    }
}


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Command is OwnableUpgradeable {
    IBattleground public battleground;
    ILootVault public lootVault;

    function updateBattleground(address _battleground) external onlyOwner {
        battleground = IBattleground(_battleground);
    }

    function updateLootVault(address _lootVault) external onlyOwner {
        lootVault = ILootVault(_lootVault);
    }
}



abstract contract UnitCommand is Command {
    IUnitManager public unitManager;

    function updateUnitManager(address _unitManager) external onlyOwner {
        unitManager = IUnitManager(_unitManager);
    }
}

