// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IAssetRegistry {
    struct Asset {
        address[] resources;
        address item;
    }

    function getAsset(uint16 version) external view returns (Asset memory);
}
