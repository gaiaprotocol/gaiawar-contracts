// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TokenAmountOperations {
    struct TokenAmount {
        IERC20 token;
        uint256 amount;
    }

    function transferAll(TokenAmount[] memory tokenAmounts, address from, address to) internal returns (bool) {
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            if (!tokenAmounts[i].token.transferFrom(from, to, tokenAmounts[i].amount)) {
                return false;
            }
        }
        return true;
    }

    function merge(TokenAmount[] memory a, TokenAmount[] memory b) internal pure returns (TokenAmount[] memory) {
        TokenAmount[] memory result = new TokenAmount[](a.length + b.length);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            result[index] = a[i];
            index++;
        }

        for (uint256 i = 0; i < b.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < result.length; j++) {
                if (result[j].token == b[i].token) {
                    result[j].amount += b[i].amount;
                    found = true;
                    break;
                }
            }

            if (!found) {
                result[index] = b[i];
                index++;
            }
        }

        assembly {
            mstore(result, index)
        }

        return result;
    }
}
