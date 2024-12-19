// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libraries/TokenAmountLib.sol";
import "../libraries/UnitQuantityLib.sol";

interface IBattleground {
    struct Coordinates {
        int16 x;
        int16 y;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitQuantityLib.UnitQuantity[] units;
        TokenAmountLib.TokenAmount[] loot;
    }

    function width() external view returns (uint16);

    function height() external view returns (uint16);

    function getTile(Coordinates memory coordinates) external view returns (Tile memory);

    function hasHeadquarters(address player) external view returns (bool);

    function updateTile(Coordinates memory coordinates, Tile memory tile) external;
}
