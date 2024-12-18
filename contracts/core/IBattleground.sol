// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ILootVault.sol";

interface IBattleground {
    struct Coordinates {
        int16 x;
        int16 y;
    }

    struct UnitQuantity {
        uint16 unitId;
        uint16 quantity;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitQuantity[] units;
        ILootVault.Loot[] loot;
    }

    function updateTile(Coordinates memory coordinates, Tile memory tile) external;
}
