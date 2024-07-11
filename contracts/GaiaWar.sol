// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GaiaWarBase.sol";

contract GaiaWar is GaiaWarBase {
    function initialize(address _wood, address _stone, address _iron, address _ducat) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        wood = IERC20(_wood);
        stone = IERC20(_stone);
        iron = IERC20(_iron);
        ducat = IERC20(_ducat);

        emit SetWood(_wood);
        emit SetStone(_stone);
        emit SetIron(_iron);
        emit SetDucat(_ducat);
    }

    function build() external {}

    function train() external {}

    function summonHero() external {}
}
