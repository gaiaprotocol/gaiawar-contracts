// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../core/IBattleground.sol";

library CoordinatesOperations {
    function manhattanDistance(
        IBattleground.Coordinates memory a,
        IBattleground.Coordinates memory b
    ) internal pure returns (uint16) {
        return uint16((a.x > b.x ? a.x - b.x : b.x - a.x) + (a.y > b.y ? a.y - b.y : b.y - a.y));
    }
}
