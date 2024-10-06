// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBuildingManager {
    struct Building {
        uint16 assetVersion;
        mapping(address => uint256) constructionCosts;
    }
}
