// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./IMapStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract TrainingManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IMapStorage public mapStorage;

    event MapStorageSet(address mapStorage);

    function initialize(address _mapStorage) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        mapStorage = IMapStorage(_mapStorage);

        emit MapStorageSet(_mapStorage);
    }

    function setMapStorage(address _mapStorage) external onlyOwner {
        mapStorage = IMapStorage(_mapStorage);

        emit MapStorageSet(_mapStorage);
    }

    function train(uint16 row, uint16 col, uint16 unitId, uint16 amount) external nonReentrant {
        //TODO:
    }
}
