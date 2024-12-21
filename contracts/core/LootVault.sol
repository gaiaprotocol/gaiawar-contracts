// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./OperatorManagement.sol";
import "./ILootVault.sol";

contract LootVault is OperatorManagement, ReentrancyGuardUpgradeable, ILootVault {
    address public protocolFeeRecipient;
    uint256 public protocolFeeRate;

    event LootTransferred(
        address indexed sender,
        address indexed recipient,
        TokenAmountLib.TokenAmount[] root,
        uint256 protocolFeeRate
    );

    function initialize(address _protocolFeeRecipient, uint256 _protocolFeeRate) external initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeRate = _protocolFeeRate;
    }

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "Invalid protocol fee recipient address");

        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function updateProtocolFeeRate(uint256 _protocolFeeRate) external onlyOwner {
        protocolFeeRate = _protocolFeeRate;
    }

    function transferLoot(
        address recipient,
        TokenAmountLib.TokenAmount[] memory loot
    ) external override onlyOperator nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(loot.length > 0, "No loot to transfer");

        for (uint256 i = 0; i < loot.length; i++) {
            uint256 amount = loot[i].amount;
            require(amount > 0, "Invalid loot amount");

            if (loot[i].tokenType == TokenAmountLib.TokenType.ERC20) {
                uint256 protocolFee = (amount * protocolFeeRate) / 1 ether;
                uint256 recipientAmount = amount - protocolFee;
                require(IERC20(loot[i].tokenAddress).transfer(recipient, recipientAmount), "Token transfer failed");
                require(
                    IERC20(loot[i].tokenAddress).transfer(protocolFeeRecipient, protocolFee),
                    "Token transfer failed"
                );
            } else if (loot[i].tokenType == TokenAmountLib.TokenType.ERC1155) {
                IERC1155(loot[i].tokenAddress).safeTransferFrom(
                    address(this),
                    recipient,
                    loot[i].tokenId,
                    loot[i].amount,
                    ""
                );
            }
        }

        emit LootTransferred(msg.sender, recipient, loot, protocolFeeRate);
    }
}
