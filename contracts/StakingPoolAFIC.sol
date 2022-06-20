//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract StakingPoolAFIC{
    //kovan AFIC  0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD
    //bsc mainnet AUC 0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564
    IERC20 public constant AFIC_TOKEN = IERC20(0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD);

    //approve 给 Manager 合约 让其 把币发给用户
    function approveToManager(address _spender,uint _amount)external {
        AFIC_TOKEN.approve(_spender, _amount);
    }

    function getGivedManagerOfAllowance(address _spender)external view returns(uint){
      return AFIC_TOKEN.allowance(address(this), _spender);
    }

}
