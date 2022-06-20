//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//主网
contract StakingHelper is Ownable{
     
    uint32 public rewardRate = 50000; //收益系数
    uint32 public endApy = 10; //到期后收益系数
    uint32 internal counter = 0;//记录订单id
    uint8 internal denominator = 100;//分母用来计算
    uint internal stopStakingTime = 0;
    bool public isStopStaking = false;

    //kovan AFIC-LP 0x40Be8dB1401b48B6B62C3ff4AB4c9aECB239ad60
    //bsc mainnet AUC-LP 0x560e6232A0a77b212CEBA2a440c5C856e45c2ca8
    IERC20 public constant LP_TOKEN = IERC20(0x560e6232A0a77b212CEBA2a440c5C856e45c2ca8);
    
    //kovan AFIC  0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD
    //bsc mainnet AUC 0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564
    IERC20 public constant RREWARD_TOKEN = IERC20(0x09caf7c71A131E73B41C68Cbc2bBb1A55d02D564);

    uint256[5] public stakingApys = [10,30,70,160,360];

    mapping(uint16 => uint256) public dayToApy;

    function setStakingSwitch(bool _state) public onlyOwner returns(bool){
        stopStakingTime = block.timestamp;
        isStopStaking = _state;
        return true;
    }

    function getApyList () external view returns(uint256[5] memory){
        return stakingApys;
    }

    function adminRewardWithdraw(uint256 amount) external onlyOwner {
        RREWARD_TOKEN.transfer(msg.sender, amount);
    }


}