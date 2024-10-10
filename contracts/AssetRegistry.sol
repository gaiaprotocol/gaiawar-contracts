// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AssetRegistry is OwnableUpgradeable {
    struct Asset {
        address[] resources;
        address item;
    }

    uint16 public currentVersion;

    mapping(uint16 => Asset) private assets;

    event AssetAdded(uint16 version, address[] resources, address item);

    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }

    function getAsset(uint16 version) external view returns (Asset memory) {
        return assets[version];
    }

    function addAsset(address[] calldata resources, address item) external onlyOwner {
        currentVersion += 1;
        uint16 version = currentVersion;
        assets[version] = Asset({resources: resources, item: item});

        emit AssetAdded(version, resources, item);
    }
}
