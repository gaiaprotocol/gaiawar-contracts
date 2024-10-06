// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IResourceManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ResourceManager is IResourceManager, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint16 public override currentVersion;
    mapping(uint16 => IERC20[]) public versions;

    event ResourcesUpdated(uint16 indexed version, IERC20[] resources);

    function initialize(address[] memory _resources) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        _updateResources(_resources);
    }

    function _updateResources(address[] memory _resources) internal {
        currentVersion++;
        versions[currentVersion] = new IERC20[](_resources.length);
        for (uint8 i = 0; i < _resources.length; i++) {
            versions[currentVersion][i] = IERC20(_resources[i]);
        }
        emit ResourcesUpdated(currentVersion, versions[currentVersion]);
    }

    function updateResources(address[] memory _resources) external onlyOwner {
        _updateResources(_resources);
    }

    function resources(uint16 version) public view override returns (IERC20[] memory) {
        return versions[version];
    }
}
