// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LootVault is OwnableUpgradeable {
    struct Loot {
        IERC20 token;
        uint256 amount;
    }

    address payable public protocolFeeRecipient;
    uint256 public protocolFeeRate;
    mapping(address => bool) public operators;

    event ProtocolFeeRecipientUpdated(address indexed recipient);
    event ProtocolFeeRateUpdated(uint256 rate);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event LootTransferred(address indexed sender, address indexed recipient, Loot[] root, uint256 protocolFeeRate);

    function initialize(address payable _protocolFeeRecipient, uint256 _protocolFeeRate) public initializer {
        __Ownable_init(msg.sender);

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
    }

    function setProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    function setProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
        protocolFeeRate = _protocolFeeRate;
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
    }

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

    function transferLoot(address recipient, Loot[] memory loot) external onlyOperator {
        require(recipient != address(0), "Invalid recipient address");
        require(loot.length > 0, "No loot to transfer");

        for (uint256 i = 0; i < loot.length; i++) {
            uint256 amount = loot[i].amount;
            require(amount > 0, "Invalid loot amount");

            uint256 protocolFee = (amount * protocolFeeRate) / 1 ether;
            uint256 recipientAmount = amount - protocolFee;

            loot[i].token.transfer(recipient, recipientAmount);
            loot[i].token.transfer(protocolFeeRecipient, protocolFee);
        }

        emit LootTransferred(msg.sender, recipient, loot, protocolFeeRate);
    }
}
