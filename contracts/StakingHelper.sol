//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingHelper is Ownable{
     
    uint32 public rewardRate = 50000; //收益系数
    uint32 public endApy = 10; //到期后收益系数
    uint32 internal counter = 0;//记录订单id
    uint8 internal denominator = 100;//分母用来计算
    uint internal lastStakingTime = 0;
    bool public isStopStaking = false;

     /* LP
        主网 0x560e6232A0a77b212CEBA2a440c5C856e45c2ca8 
        测试 0x680Ab5E28c7FEe950A911EE0139dB01b2284A686
     */
    IERC20 public constant LP_TOKEN = IERC20(0x560e6232A0a77b212CEBA2a440c5C856e45c2ca8);//LP cake  主网 0x560e6232A0a77b212CEBA2a440c5C856e45c2ca8 测试 0x680Ab5E28c7FEe950A911EE0139dB01b2284A686
    /*  AUC
        主网 0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564 
        测试 0xf5e0dE62a6e3692CABfDE999DFB38AbFe8518Ad4
     */
    IERC20 public constant RREWARD_TOKEN = IERC20(0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564);//AUC 主网 0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564 测试 0xf5e0dE62a6e3692CABfDE999DFB38AbFe8518Ad4

    uint16[5] public stakingApys = [10,30,70,160,360];

    mapping(uint16 => uint16) public dayToApy;

    function setStakingSwitch(bool _state) public onlyOwner returns(bool){
        lastStakingTime = block.timestamp;
        isStopStaking = _state;
        return true;
    }

    function getApyList () external view returns(uint16[5] memory){
        return stakingApys;
    }

    function adminRewardWithdraw(uint256 amount) external onlyOwner {
        RREWARD_TOKEN.transfer(msg.sender, amount);
    }


}