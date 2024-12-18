// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../IMapStorage.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

contract MockMapStorage is ERC1155HolderUpgradeable {
    mapping(uint16 => mapping(uint16 => address)) private tileOccupants;
    mapping(uint16 => mapping(uint16 => uint16)) private tileBuildingIds;
    mapping(uint16 => mapping(uint16 => IMapStorage.UnitAmount[])) private tileUnits;

    function getTileOccupant(uint16 row, uint16 col) external view returns (address) {
        return tileOccupants[row][col];
    }

    function getTileBuildingId(uint16 row, uint16 col) external view returns (uint16) {
        return tileBuildingIds[row][col];
    }

    function getTileUnits(uint16 row, uint16 col) external view returns (IMapStorage.UnitAmount[] memory) {
        return tileUnits[row][col];
    }

    function updateTileUnits(uint16 row, uint16 col, IMapStorage.UnitAmount[] memory units) external {
        tileUnits[row][col] = units;
    }

    // Additional function to set up test state
    function setTileOccupant(uint16 row, uint16 col, address occupant) external {
        tileOccupants[row][col] = occupant;
    }

    function setTileBuildingId(uint16 row, uint16 col, uint16 buildingId) external {
        tileBuildingIds[row][col] = buildingId;
    }
}
