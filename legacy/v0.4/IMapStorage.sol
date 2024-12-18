// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMapStorage {
    struct UnitAmount {
        uint16 unitId;
        uint16 amount;
    }

    function mapRows() external view returns (uint16);

    function mapCols() external view returns (uint16);

    function getTileOccupant(uint16 row, uint16 col) external view returns (address);

    function getTileBuildingId(uint16 row, uint16 col) external view returns (uint16);

    function getTileUnits(uint16 row, uint16 col) external view returns (UnitAmount[] memory);

    function updateTileOccupant(uint16 row, uint16 col, address occupant) external;

    function updateTileBuildingId(uint16 row, uint16 col, uint16 buildingId) external;

    function updateTileUnits(uint16 row, uint16 col, UnitAmount[] memory units) external;
}
