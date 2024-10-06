// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IResourceManager {
    function currentVersion() external view returns (uint16);

    function resources(uint16 version) external view returns (IERC20[] memory);
}
