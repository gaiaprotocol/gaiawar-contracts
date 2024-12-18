// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TokenOperations {
    struct TokenAmount {
        IERC20 token;
        uint256 amount;
    }

    function transferTokens(TokenAmount[] memory amounts, address from, address to) internal returns (bool) {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (!amounts[i].token.transferFrom(from, to, amounts[i].amount)) {
                return false;
            }
        }
        return true;
    }
}
