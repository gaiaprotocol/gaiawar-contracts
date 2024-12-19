// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

library TokenAmountLib {
    enum TokenType {
        ERC20,
        ERC1155
    }

    struct TokenAmount {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    function transferAll(TokenAmount[] memory tokenAmounts, address from, address to) internal {
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            if (tokenAmounts[i].tokenType == TokenType.ERC20) {
                require(
                    IERC20(tokenAmounts[i].tokenAddress).transferFrom(from, to, tokenAmounts[i].amount),
                    "Token transfer failed"
                );
            } else if (tokenAmounts[i].tokenType == TokenType.ERC1155) {
                IERC1155(tokenAmounts[i].tokenAddress).safeTransferFrom(
                    from,
                    to,
                    tokenAmounts[i].tokenId,
                    tokenAmounts[i].amount,
                    ""
                );
            }
        }
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
                if (result[j].tokenAddress == b[i].tokenAddress && result[j].tokenId == b[i].tokenId) {
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
