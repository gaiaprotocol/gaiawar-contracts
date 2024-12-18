// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IBuildings.sol";

contract Buildings is OwnableUpgradeable, IBuildings {
    struct Building {
        uint16 previousBuildingId;
        TokenOperations.TokenAmount[] constructionCost;
        bool isHeadquarters;
        uint16 constructionRange;
        bool canBeConstructed;
    }

    uint16 public nextBuildingId;
    mapping(uint16 => Building) public buildings;

    function getParentBuildingId(uint16 buildingId) external view returns (uint16) {
        return buildings[buildingId].previousBuildingId;
    }

    function getConstructionCost(uint16 buildingId) external view returns (TokenOperations.TokenAmount[] memory) {
        return buildings[buildingId].constructionCost;
    }

    function isHeadquarters(uint16 buildingId) external view returns (bool) {
        return buildings[buildingId].isHeadquarters;
    }

    function getConstructionRange(uint16 buildingId) external view returns (uint16) {
        return buildings[buildingId].constructionRange;
    }

    function canBeConstructed(uint16 buildingId) external view returns (bool) {
        return buildings[buildingId].canBeConstructed;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function addBuilding(
        uint16 previousBuildingId,
        TokenOperations.TokenAmount[] calldata constructionCost,
        bool isHeadquarters,
        uint16 constructionRange,
        bool canBeConstructed
    ) external onlyOwner {
        require(previousBuildingId < nextBuildingId, "Previous building does not exist");
        require(constructionCost.length > 0, "Construction cost must be provided");

        uint16 buildingId = nextBuildingId;
        nextBuildingId += 1;

        buildings[buildingId] = Building({
            previousBuildingId: previousBuildingId,
            constructionCost: constructionCost,
            isHeadquarters: isHeadquarters,
            constructionRange: constructionRange,
            canBeConstructed: canBeConstructed
        });
    }

    function setConstructability(uint16 buildingId, bool canBeConstructed) external onlyOwner {
        require(buildingId < nextBuildingId, "Building does not exist");

        buildings[buildingId].canBeConstructed = canBeConstructed;
    }
}
