// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILootVault {
    struct Loot {
        IERC20 token;
        uint256 amount;
    }

    function transferLoot(address recipient, Loot[] memory loot) external;
}
