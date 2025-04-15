// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

abstract contract OperatorManagement is OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => bool) public operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    function addOperators(address[] calldata _operators) external onlyOwner {
        require(_operators.length > 0, "No operators provided");

        for (uint256 i = 0; i < _operators.length; i++) {
            address operator = _operators[i];
            require(operator != address(0), "Invalid operator address");
            require(!operators[operator], "Already an operator");

            operators[operator] = true;
            emit OperatorAdded(operator);
        }
    }

    function removeOperators(address[] calldata _operators) external onlyOwner {
        require(_operators.length > 0, "No operators provided");

        for (uint256 i = 0; i < _operators.length; i++) {
            address operator = _operators[i];
            require(operators[operator], "Not an operator");

            operators[operator] = false;
            emit OperatorRemoved(operator);
        }
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Not an operator");
        _;
    }
}
