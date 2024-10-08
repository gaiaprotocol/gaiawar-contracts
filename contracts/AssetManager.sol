// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IAssetManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract AssetManager is IAssetManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint16 public currentVersion;

    mapping(uint16 => Asset) private assets;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        currentVersion = 1;
    }

    function getAsset(uint16 version) external view override returns (Asset memory) {
        return assets[version];
    }

    function addAsset(address[] calldata resources, address item) external onlyOwner {
        uint16 version = ++currentVersion;
        assets[version] = Asset({resources: resources, item: item});
    }
}
