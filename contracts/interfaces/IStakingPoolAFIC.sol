//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
interface IStakingPoolAFIC{

    function approveToManager(address _spender,uint _amount)external;

    function getGivedManagerOfAllowance(address _spender)external view returns(uint);

}