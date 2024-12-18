// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./OperatorManagement.sol";
import "./ILootVault.sol";

contract LootVault is OperatorManagement, ILootVault {
    address payable public protocolFeeRecipient;
    uint256 public protocolFeeRate;

    event ProtocolFeeRecipientUpdated(address indexed recipient);
    event ProtocolFeeRateUpdated(uint256 rate);
    event LootTransferred(address indexed sender, address indexed recipient, Loot[] root, uint256 protocolFeeRate);

    function initialize(address payable _protocolFeeRecipient, uint256 _protocolFeeRate) public initializer {
        __Ownable_init(msg.sender);

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;

        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
    }

    function updateProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    function updateProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
        protocolFeeRate = _protocolFeeRate;
        emit ProtocolFeeRateUpdated(_protocolFeeRate);
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
