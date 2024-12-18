// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UnitQuantityOperations {
    struct UnitQuantity {
        uint16 unitId;
        uint16 quantity;
    }

    function subtract(
        UnitQuantity[] memory a,
        UnitQuantity[] memory b
    ) internal pure returns (UnitQuantity[] memory result) {
        uint256 resultLength = 0;

        for (uint256 i = 0; i < a.length; i++) {
            for (uint256 j = 0; j < b.length; j++) {
                if (a[i].unitId == b[j].unitId) {
                    require(a[i].quantity >= b[j].quantity, "Not enough units to subtract");
                    a[i].quantity -= b[j].quantity;
                    break;
                }
            }

            if (a[i].quantity > 0) {
                resultLength++;
            }
        }

        result = new UnitQuantity[](resultLength);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i].quantity > 0) {
                result[index] = a[i];
                index++;
            }
        }
    }

    function merge(UnitQuantity[] memory a, UnitQuantity[] memory b) internal pure returns (UnitQuantity[] memory) {
        UnitQuantity[] memory result = new UnitQuantity[](a.length + b.length);

        uint256 index = 0;
        for (uint256 i = 0; i < a.length; i++) {
            result[index] = a[i];
            index++;
        }

        for (uint256 i = 0; i < b.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < result.length; j++) {
                if (result[j].unitId == b[i].unitId) {
                    result[j].quantity += b[i].quantity;
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
