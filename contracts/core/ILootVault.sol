// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/TokenAmountOperations.sol";

interface ILootVault {
    function transferLoot(address recipient, TokenAmountOperations.TokenAmount[] memory loot) external;
}
