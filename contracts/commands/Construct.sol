// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./base/BuildingCommand.sol";

contract Construct is BuildingCommand {
    uint16 public headquartersSearchRange;
    uint16 public enemyBuildingSearchRange;

    function initialize(
        address _battleground,
        address _lootVault,
        address _buildingManager,
        uint16 _headquartersSearchRange,
        uint16 _enemyBuildingSearchRange
    ) external initializer {
        __Ownable_init(msg.sender);

        battleground = IBattleground(_battleground);
        lootVault = ILootVault(_lootVault);
        buildingManager = IBuildingManager(_buildingManager);
        headquartersSearchRange = _headquartersSearchRange;
        enemyBuildingSearchRange = _enemyBuildingSearchRange;
    }

    function updateHeadquartersSearchRange(uint16 _headquartersSearchRange) external onlyOwner {
        headquartersSearchRange = _headquartersSearchRange;
    }

    function updateEnemyBuildingSearchRange(uint16 _enemyBuildingSearchRange) external onlyOwner {
        enemyBuildingSearchRange = _enemyBuildingSearchRange;
    }
}
