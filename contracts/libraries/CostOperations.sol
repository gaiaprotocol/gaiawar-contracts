// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CostOperations {
    struct Cost {
        IERC20 token;
        uint256 amount;
    }

    function transferFrom(Cost[] memory cost, address from, address to) internal returns (bool) {
        for (uint256 i = 0; i < cost.length; i++) {
            if (!cost[i].token.transferFrom(from, to, cost[i].amount)) {
                return false;
            }
        }
        return true;
    }
}
