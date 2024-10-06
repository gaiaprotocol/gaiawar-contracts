// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

type Coord is uint16;

contract GaiaWar is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct UnitAmount {
        uint16 unitId;
        uint16 amount;
    }

    struct Tile {
        address occupant;
        uint16 buildingId;
        UnitAmount[] units;
    }

    mapping(Coord => mapping(Coord => Tile)) public battlefield;

    function moveUnits(Coord fromRow, Coord fromCol, Coord toRow, Coord toCol, UnitAmount[] calldata units) external {}

    function attack(Coord fromRow, Coord fromCol, Coord toRow, Coord toCol) external {}
}
