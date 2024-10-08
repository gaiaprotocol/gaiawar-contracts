// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IUnitManager.sol";
import "./IAssetManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract UnitManager is IUnitManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    mapping(uint256 => Unit) private units;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function getUnit(uint256 unitId) external view override returns (Unit memory) {
        return units[unitId];
    }

    function addUnit(
        uint256 unitId,
        uint16 hp,
        uint16 damage,
        uint8 attackRange,
        uint16 assetVersion,
        uint256[] calldata trainCosts,
        uint256 preUpgradeUnitId,
        uint256 upgradeItemId
    ) external onlyOwner {
        require(units[unitId].hp == 0, "Unit already exists");

        units[unitId] = Unit({
            hp: hp,
            damage: damage,
            attackRange: attackRange,
            assetVersion: assetVersion,
            trainCosts: trainCosts,
            preUpgradeUnitId: preUpgradeUnitId,
            upgradeItemId: upgradeItemId
        });
    }
}
