// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAssetManager {
    struct Asset {
        address[] resources;
        address item;
    }

    function currentVersion() external view returns (uint16);

    function getAsset(uint16 version) external view returns (Asset memory);
}
