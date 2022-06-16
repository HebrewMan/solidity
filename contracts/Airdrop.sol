/**
 *Submitted for verification at BscScan.com on 2020-09-22
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable {

    function airdrop(address[] memory _recipients, uint _value, address _tokenAddress)public onlyOwner returns (bool) {
        require(_recipients.length > 0,"invalid recipient");
        IERC20 Token = IERC20(_tokenAddress);

        for(uint i; i < _recipients.length; i++){
            Token.transfer(_recipients[i], _value);
        }

        emit Airdropped(_recipients, _value, _tokenAddress);
        return true;
    }

    function withdrawExcessToken(address _tokenAddress)public onlyOwner  { 
        IERC20 Token = IERC20(_tokenAddress);
        Token.transfer(owner(), Token.balanceOf(address(this)));
    }

    /*========== EVENTS =========*/
    event Airdropped (address[] _recipients, uint _value, address _tokenAddress);

}

