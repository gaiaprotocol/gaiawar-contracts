// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OperatorManagement is OwnableUpgradeable {
    mapping(address => bool) public operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        require(!operators[operator], "Already an operator");

        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(operators[operator], "Not an operator");

        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Not an operator");
        _;
    }
}