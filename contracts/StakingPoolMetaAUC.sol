//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract StakingPoolAFICLP is Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint16;

    /* 
        发行 kovan Meta NFT用于测试
        发行 kovan GEE 用于出矿测试
        调用 AUC 接口 用于燃烧测试。
    */
    struct UserStakingTotalInfo {
        uint256 stakedAmount; //质押总量
        uint256 rewardAmount; //出了多少矿
        uint256 hadRewardAmount; //已经claim了多少矿
    }

    struct UserStakingInfo {
        address user;
        uint16 stakedDays; //质押类型 多少天（测试环境 分钟）
        uint32 orderId; // 订单id
        uint32 apy; //当前收益率
        uint256 startingTime; //质押开始时间
        uint256 endTime; //质押结束时间
        uint256 lastTime; //最近一次更新的时间
        uint256 stakedAmount; //质押nft 数量
        uint256 rewardAmount; //可领取的收益  当前订单 有多少收益（需要mapping解决）
        uint256 hadRewardAmount; //已经领取的收益 当前订单 领取了多少收益（需要mapping解决）
        uint256 rewardPerSecondToken; //用户的每单位(秒) token 奖励数
    }

    function stake(uint[] memory _nfts)external{
        //授权AUC NFT
        //燃烧 1000 AUC
        //到期之后才能 解押 期间无法领取收益
        
    }
         
    

    /* 10 公式： 日收益 = 质押数量 * 日收益率 * 收益系数 */
    // function _computeStakingRewardAmount(UserStakingInfo memory _OrderInfo) private view returns (uint256){
    //     uint256 RewardsAmount;
    //     uint256 callTime;
    //     uint256 computeTime;

    //     _OrderInfo.endTime <= block.timestamp? callTime = _OrderInfo.endTime : callTime = block.timestamp;
    //     _OrderInfo.hadRewardAmount > 0? computeTime =  _OrderInfo.lastTime : computeTime = _OrderInfo.startingTime;
    //     //lastTime > endTIme;
    //     if(computeTime>callTime){
    //         RewardsAmount = 0;
    //     }else{
    //         RewardsAmount = (callTime - computeTime).mul( _OrderInfo.rewardPerSecondToken);
    //     }

    //     return RewardsAmount/1e10;
    // }
}
