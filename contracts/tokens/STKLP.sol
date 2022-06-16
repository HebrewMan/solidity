// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract STKLP is ERC20 {
    constructor(uint256 initialSupply) ERC20("Test token for aaron in staking", "AFICLP") {
        _mint(msg.sender, initialSupply);
    }
}