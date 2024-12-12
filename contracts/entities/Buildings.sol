// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Buildings is OwnableUpgradeable {
    struct ConstructionCost {
        address tokenAddress;
        uint256 amount;
    }

    struct Building {
        uint256 previousBuildingId;
        ConstructionCost[] constructionCosts;
        bool isHeadquarters;
        bool canBeConstructed;
    }

    uint256 public nextBuildingId;
    mapping(uint256 => Building) public buildings;

    function initialize() public initializer {
        __Ownable_init(msg.sender);

        nextBuildingId = 1;
    }

    function addBuilding(
        uint256 previousBuildingId,
        ConstructionCost[] calldata constructionCosts,
        bool isHeadquarters,
        bool canBeConstructed
    ) external onlyOwner {
        require(previousBuildingId < nextBuildingId, "Previous building does not exist");
        require(constructionCosts.length > 0, "Construction costs must be provided");

        uint256 buildingId = nextBuildingId;
        nextBuildingId += 1;

        buildings[buildingId] = Building({
            previousBuildingId: previousBuildingId,
            constructionCosts: constructionCosts,
            isHeadquarters: isHeadquarters,
            canBeConstructed: canBeConstructed
        });
    }

    function setConstructability(uint256 buildingId, bool canBeConstructed) external onlyOwner {
        require(buildingId < nextBuildingId, "Building does not exist");

        Building storage building = buildings[buildingId];
        building.canBeConstructed = canBeConstructed;
    }
}
