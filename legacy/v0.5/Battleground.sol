// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TokenOperations.sol";
import "./entities/IBuildings.sol";

contract Battleground is OwnableUpgradeable {
    using TokenOperations for TokenOperations.TokenAmount[];

    IBuildings public buildingsContract;
    address public constructionContract;
    address public trainingContract;
    address public attackContract;

    uint256 public maxUnitsPerTile;
    uint256 public protocolFeeRate;
    address payable public treasury;

    struct Coordinates {
        int16 x;
        int16 y;
    }

    struct UnitQuantity {
        uint16 unitId;
        uint16 quantity;
    }

    struct Tile {
        address owner;
        uint16 buildingId;
        UnitQuantity[] units;
        TokenOperations.TokenAmount[] uncollectedLoot;
    }

    int16 public minTileX;
    int16 public minTileY;
    int16 public maxTileX;
    int16 public maxTileY;

    mapping(int16 => mapping(int16 => Tile)) public tiles;
    mapping(address => Coordinates[]) public userHeadquarters;

    event BuildingsContractUpdated(address buildingsContract);
    event ConstructionContractUpdated(address constructionContract);
    event TrainingContractUpdated(address trainingContract);
    event AttackContractUpdated(address attackContract);

    event MaxUnitsPerTileUpdated(uint256 maxUnitsPerTile);
    event TreasuryUpdated(address indexed treasury);
    event ProtocolFeeRateUpdated(uint256 rate);

    event BuildingPlaced(int16 x, int16 y, address indexed owner, uint16 buildingId);
    event UnitsAdded(int16 x, int16 y, address indexed owner, uint16 unitId, uint16 quantity);

    function getTile(int16 x, int16 y) external view returns (Tile memory) {
        return tiles[x][y];
    }

    function getTiles(Coordinates[] memory coordinates) external view returns (Tile[] memory) {
        uint256 count = coordinates.length;

        Tile[] memory result = new Tile[](count);
        for (uint256 i = 0; i < count; i++) {
            Coordinates memory coordinate = coordinates[i];
            result[i] = tiles[coordinate.x][coordinate.y];
        }

        return result;
    }

    function hasHeadquarters(address user) external view returns (bool) {
        return userHeadquarters[user].length > 0;
    }

    function initialize(
        int16 _minTileX,
        int16 _minTileY,
        int16 _maxTileX,
        int16 _maxTileY,
        uint256 _maxUnitsPerTile,
        address payable _treasury,
        uint256 _protocolFeeRate
    ) public initializer {
        __Ownable_init(msg.sender);

        minTileX = _minTileX;
        minTileY = _minTileY;
        maxTileX = _maxTileX;
        maxTileY = _maxTileY;

        maxUnitsPerTile = _maxUnitsPerTile;
        treasury = _treasury;
        protocolFeeRate = _protocolFeeRate;

        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
        emit TreasuryUpdated(_treasury);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
    }

    function setMaxUnitsPerTile(uint256 _maxUnitsPerTile) external onlyOwner {
        maxUnitsPerTile = _maxUnitsPerTile;
        emit MaxUnitsPerTileUpdated(_maxUnitsPerTile);
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setProtocolFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1 ether, "Fee rate exceeds maximum");
        protocolFeeRate = _rate;
        emit ProtocolFeeRateUpdated(_rate);
    }

    function setBuildingsContract(address _buildingsContract) external onlyOwner {
        buildingsContract = IBuildings(_buildingsContract);
        emit BuildingsContractUpdated(_buildingsContract);
    }

    function setConstructionContract(address _constructionContract) external onlyOwner {
        constructionContract = _constructionContract;
        emit ConstructionContractUpdated(_constructionContract);
    }

    function setTrainingContract(address _trainingContract) external onlyOwner {
        trainingContract = _trainingContract;
        emit TrainingContractUpdated(_trainingContract);
    }

    function setAttackContract(address _attackContract) external onlyOwner {
        attackContract = _attackContract;
        emit AttackContractUpdated(_attackContract);
    }

    modifier onlyConstructionContract() {
        require(msg.sender == constructionContract, "Only construction contract can call this function");
        _;
    }

    function _withinBounds(int16 x, int16 y) private view returns (bool) {
        return (x >= minTileX && x <= maxTileX && y >= minTileY && y <= maxTileY);
    }

    function _addHQCoordinate(address user, int16 x, int16 y) private {
        userHeadquarters[user].push(Coordinates(x, y));
    }

    function _removeHQCoordinate(address user, int16 x, int16 y) private {
        Coordinates[] storage userHQs = userHeadquarters[user];
        uint256 length = userHQs.length;

        for (uint256 i = 0; i < length; i++) {
            if (userHQs[i].x == x && userHQs[i].y == y) {
                userHQs[i] = userHQs[length - 1];
                userHQs.pop();
                break;
            }
        }
    }

    function placeBuilding(int16 x, int16 y, address newOwner, uint16 buildingId) external onlyConstructionContract {
        require(newOwner != address(0), "New owner cannot be zero address");
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile memory existingTile = tiles[x][y];

        require(
            existingTile.owner == address(0) || existingTile.owner == newOwner,
            "Tile already occupied by another user"
        );

        Tile storage tile = tiles[x][y];
        tile.owner = newOwner;
        tile.buildingId = buildingId;

        if (existingTile.owner != address(0) && buildingsContract.isHeadquarters(existingTile.buildingId)) {
            if (!buildingsContract.isHeadquarters(buildingId)) {
                _removeHQCoordinate(existingTile.owner, x, y);
            }
        } else if (buildingsContract.isHeadquarters(buildingId)) {
            _addHQCoordinate(newOwner, x, y);
        }

        emit BuildingPlaced(x, y, newOwner, buildingId);
    }

    modifier onlyTrainingContract() {
        require(msg.sender == trainingContract, "Only training contract can call this function");
        _;
    }

    function addUnits(int16 x, int16 y, uint16 unitId, uint16 quantity) external onlyTrainingContract {
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile storage tile = tiles[x][y];

        bool found = false;
        uint256 totalUnits = 0;

        for (uint256 i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitId == unitId) {
                tile.units[i].quantity += quantity;
                found = true;
            }
            totalUnits += tile.units[i].quantity;
        }

        require(totalUnits <= maxUnitsPerTile, "Total units exceed maximum per tile");

        if (!found) {
            tile.units.push(UnitQuantity(unitId, quantity));
        }

        emit UnitsAdded(x, y, tile.owner, unitId, quantity);
    }

    function reorderUnits(int16 x, int16 y, uint16[] calldata newOrder) external {
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile storage tile = tiles[x][y];
        require(tile.owner == msg.sender, "Not the tile owner");
        require(newOrder.length == tile.units.length, "Invalid order length");

        UnitQuantity[] memory newUnits = new UnitQuantity[](newOrder.length);
        bool[] memory used = new bool[](newOrder.length);

        for (uint256 i = 0; i < newOrder.length; i++) {
            require(!used[newOrder[i]], "Duplicate index");
            require(newOrder[i] < tile.units.length, "Invalid index");

            newUnits[i] = tile.units[newOrder[i]];
            used[newOrder[i]] = true;
        }

        tile.units = newUnits;
    }

    modifier onlyAttackContract() {
        require(msg.sender == attackContract, "Only attack contract can call this function");
        _;
    }

    function updateTile(
        int16 x,
        int16 y,
        address newOwner,
        UnitQuantity[] memory units,
        TokenOperations.TokenAmount[] memory uncollectedLoot
    ) external onlyAttackContract {
        require(_withinBounds(x, y), "Coordinates out of bounds");

        Tile storage tile = tiles[x][y];
        address originalOwner = tile.owner;
        uint16 originalBuildingId = tile.buildingId;

        tile.owner = newOwner;
        tile.units = units;
        tile.uncollectedLoot = uncollectedLoot;

        if (originalOwner != newOwner) {
            TokenOperations.TokenAmount[] memory loot = buildingsContract.getConstructionCost(originalBuildingId);
            if (newOwner != address(0)) {
                loot.transferTokens(address(this), newOwner);
            } else {
                addUncollectedLoot(x, y, loot);
            }
            tile.buildingId = 0;
        }
    }

    function addUncollectedLoot(int16 x, int16 y, TokenOperations.TokenAmount[] memory loot) public onlyAttackContract {
        require(_withinBounds(x, y), "Coordinates out of bounds");

        TokenOperations.TokenAmount[] memory totalLoot = tiles[x][y].uncollectedLoot;

        if (totalLoot.length == 0) {
            totalLoot = loot;
        } else {
            for (uint256 i = 0; i < loot.length; i++) {
                bool tokenFound = false;
                for (uint256 j = 0; j < totalLoot.length; j++) {
                    if (totalLoot[j].token == loot[i].token) {
                        totalLoot[j].amount += loot[i].amount;
                        tokenFound = true;
                        break;
                    }
                }
                if (!tokenFound) {
                    TokenOperations.TokenAmount[] memory newTotalLoot = new TokenOperations.TokenAmount[](
                        totalLoot.length + 1
                    );
                    for (uint256 j = 0; j < totalLoot.length; j++) {
                        newTotalLoot[j] = totalLoot[j];
                    }
                    newTotalLoot[totalLoot.length] = loot[i];
                    totalLoot = newTotalLoot;
                }
            }
        }

        tiles[x][y].uncollectedLoot = totalLoot;
    }
}
