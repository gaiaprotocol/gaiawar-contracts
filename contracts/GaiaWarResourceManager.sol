// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GaiaWarResourceManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    IERC20 public wood;
    IERC20 public stone;
    IERC20 public iron;
    IERC20 public ducat;

    event SetWood(address indexed wood);
    event SetStone(address indexed stone);
    event SetIron(address indexed iron);
    event SetDucat(address indexed ducat);

    function setWood(address _wood) external onlyOwner {
        wood = IERC20(_wood);
        emit SetWood(_wood);
    }

    function setStone(address _stone) external onlyOwner {
        stone = IERC20(_stone);
        emit SetStone(_stone);
    }

    function setIron(address _iron) external onlyOwner {
        iron = IERC20(_iron);
        emit SetIron(_iron);
    }

    function setDucat(address _ducat) external onlyOwner {
        ducat = IERC20(_ducat);
        emit SetDucat(_ducat);
    }
}
