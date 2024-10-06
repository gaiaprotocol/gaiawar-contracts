// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

type Coordinate is uint16;

contract BattlefieldManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public buildingManager;
    address public unitManager;
    address public combatSystem;

    modifier onlyBuildingManager() {
        require(msg.sender == buildingManager, "Caller is not the BuildingManager");
        _;
    }

    modifier onlyUnitManager() {
        require(msg.sender == unitManager, "Caller is not the UnitManager");
        _;
    }

    modifier onlyCombatSystem() {
        require(msg.sender == combatSystem, "Caller is not the CombatSystem");
        _;
    }

    modifier onlyBuildingManagerOrCombatSystem() {
        require(
            msg.sender == buildingManager || msg.sender == combatSystem,
            "Caller is neither BuildingManager nor CombatSystem"
        );
        _;
    }

    struct UnitInfo {
        uint16 unitType;
        uint16 quantity;
    }

    struct ResourceInfo {
        uint16 resourceVersion;
        mapping(uint8 => uint256) amounts;
    }

    struct Tile {
        address occupant;
        uint16 buildingType;
        uint16 buildingLevel;
        UnitInfo[] units;
        ResourceInfo[] usedResources;
    }

    mapping(Coordinate => mapping(Coordinate => Tile)) public battlefield;

    function setOccupant(
        Coordinate _row,
        Coordinate _col,
        address _occupant
    ) external onlyBuildingManagerOrCombatSystem {
        battlefield[_row][_col].occupant = _occupant;
    }

    function setBuilding(
        Coordinate _row,
        Coordinate _col,
        uint16 _buildingType,
        uint16 _buildingLevel
    ) external onlyBuildingManager {
        battlefield[_row][_col].buildingType = _buildingType;
        battlefield[_row][_col].buildingLevel = _buildingLevel;
    }

    function addUnit(Coordinate _row, Coordinate _col, uint16 _unitType, uint16 _quantity) external onlyUnitManager {
        Tile storage tile = battlefield[_row][_col];
        bool unitExists = false;

        for (uint i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitType == _unitType) {
                tile.units[i].quantity += _quantity;
                unitExists = true;
                break;
            }
        }

        if (!unitExists) {
            tile.units.push(UnitInfo({unitType: _unitType, quantity: _quantity}));
        }
    }

    function removeUnit(Coordinate _row, Coordinate _col, uint16 _unitType, uint16 _quantity) external onlyUnitManager {
        Tile storage tile = battlefield[_row][_col];

        for (uint i = 0; i < tile.units.length; i++) {
            if (tile.units[i].unitType == _unitType) {
                tile.units[i].quantity -= _quantity;
                if (tile.units[i].quantity == 0) {
                    tile.units[i] = tile.units[tile.units.length - 1];
                    tile.units.pop();
                }
                break;
            }
        }
    }

    struct ResourceAmount {
        uint8 resourceIndex;
        uint256 amount;
    }

    function setResourceAmounts(
        Coordinate _row,
        Coordinate _col,
        uint16 _resourceVersion,
        ResourceAmount[] calldata _resourceAmounts
    ) external onlyBuildingManager {
        Tile storage tile = battlefield[_row][_col];
        bool resourceExists = false;
        uint16 resourceIndex;

        for (uint16 i = 0; i < tile.usedResources.length; i++) {
            if (tile.usedResources[i].resourceVersion == _resourceVersion) {
                resourceExists = true;
                resourceIndex = i;
                break;
            }
        }

        if (!resourceExists) {
            resourceIndex = uint16(tile.usedResources.length);
            tile.usedResources.push();
            tile.usedResources[resourceIndex].resourceVersion = _resourceVersion;
        }

        for (uint8 i = 0; i < _resourceAmounts.length; i++) {
            tile.usedResources[resourceIndex].amounts[_resourceAmounts[i].resourceIndex] = _resourceAmounts[i].amount;
        }
    }
}
