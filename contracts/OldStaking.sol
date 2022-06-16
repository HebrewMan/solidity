//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./StakingHelper.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingRewards is StakingHelper{
    using SafeMath for uint256;
    using SafeMath for uint16;

    mapping(address => UserStakingInfo[]) internal userToStakingList; //address to all user's staking order.
    mapping(address => mapping(uint32 => UserStakingInfo)) internal userToCurrtentStaking; //address to current user staked info.
    mapping(address => UserStakingTotalInfo) internal userToTotalInfo;
    // mapping(uint32 => uint256) public UserToBeginningStartTime;

    UserStakingInfo[] public poolList;

    constructor() {
        dayToApy[30] = stakingApys[0];
        dayToApy[60] = stakingApys[1];
        dayToApy[90] = stakingApys[2];
        dayToApy[120] = stakingApys[3];
        dayToApy[150] = stakingApys[4];
    }

    modifier checkUserIsStaked(address _addr) {
        require(userToStakingList[_addr][0].stakedAmount > 0, "no staking order");
        _;
    }

    modifier checkOrderIsExist(uint32 _orderId) {
        require( userToCurrtentStaking[_msgSender()][_orderId].stakedAmount > 0, "order does not exist");
        _;
    }

    modifier checkPoolBlanceOf(){
        require(this.getRemainingReward() >= 100 * 1e18,"RREWARD_TOKEN: Pool balance is less than 100");
        require(RREWARD_TOKEN.balanceOf(address(this)) >= _getUsersTotalRewards(),"RREWARD_TOKEN: Insufficient pool balance");
        _;
    }

    modifier checkStakingState(){
         require(isStopStaking == false,"StakingPool: Staking mining is over");
         _;
    }

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
        uint256 stakedAmount; //质押份额
        uint256 rewardAmount; //可领取的收益  当前订单 有多少收益（需要mapping解决）
        uint256 hadRewardAmount; //已经领取的收益 当前订单 领取了多少收益（需要mapping解决）
        uint256 rewardPerSecondToken; //用户的每单位(秒) token 奖励数
        uint256 rewardPerSecondTokenAfter; //质押期限结束后用户的每单位(秒) token 奖励数
    }

    function stake(uint16 _days, uint256 _amount) external checkPoolBlanceOf checkStakingState{
        counter++;
        UserStakingInfo memory OrderInfo;
        OrderInfo.user = _msgSender();
        OrderInfo.startingTime = block.timestamp;
        OrderInfo.endTime = block.timestamp + _days.mul(60); //测试环境 分钟 * 60秒。 （min）正式需要* 86400秒
        OrderInfo.orderId = counter;

        OrderInfo.stakedDays = _days;
        OrderInfo.apy = dayToApy[_days];
        OrderInfo.stakedAmount = _amount;

        OrderInfo.rewardPerSecondToken = _amount * dayToApy[_days]/ 365 / 86400 / denominator * rewardRate; //结束前每秒的收益
        OrderInfo.rewardPerSecondTokenAfter = _amount * endApy / 365 / 86400 / denominator * rewardRate;

        poolList.push(OrderInfo);
        userToStakingList[_msgSender()].push(OrderInfo);
        userToCurrtentStaking[_msgSender()][OrderInfo.orderId] = OrderInfo;
        userToTotalInfo[_msgSender()].stakedAmount += _amount;

        // UserToBeginningStartTime[counter] = block.timestamp;

        //先授权给 pool
        LP_TOKEN.transferFrom(_msgSender(), address(this), _amount);

        emit Staked(_days, _amount);
    }

    function withdraw(uint32 _orderId) external checkOrderIsExist(_orderId) {
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];
        UserStakingInfo memory OrderInfo = userToCurrtentStaking[_msgSender()][_orderId];

        OrderInfo.rewardAmount = _computeStakingRewardAmount(OrderInfo);
        userToTotalInfo[_msgSender()].hadRewardAmount += OrderInfo.rewardAmount;

        for (uint256 i; i < poolList.length; i++) {
            if (_orderId == poolList[i].orderId) {
                poolList[i] = poolList[poolList.length - 1];
                poolList.pop();
            }
        }

        for (uint256 i; i < orderList.length; i++) {
            if (_orderId == orderList[i].orderId) {
                orderList[i] = orderList[orderList.length - 1];
                orderList.pop();
            }
        }

        LP_TOKEN.transfer(_msgSender(), OrderInfo.stakedAmount);
        RREWARD_TOKEN.transfer(_msgSender(), OrderInfo.rewardAmount);

        delete userToCurrtentStaking[_msgSender()][_orderId];
        // delete UserToBeginningStartTime[_orderId];

        emit Withdrawed(_orderId,OrderInfo.stakedAmount,OrderInfo.rewardAmount);
    }

    function claim(uint32 _orderId) external checkStakingState checkOrderIsExist(_orderId){
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];
        UserStakingInfo storage OrderInfo = userToCurrtentStaking[_msgSender()][_orderId];

        OrderInfo.rewardAmount = _computeStakingRewardAmount(OrderInfo);
        OrderInfo.hadRewardAmount += OrderInfo.rewardAmount;
        userToTotalInfo[_msgSender()].hadRewardAmount += OrderInfo.rewardAmount;

        if (OrderInfo.endTime <= block.timestamp) {
            OrderInfo.rewardPerSecondToken = 0;
        }

        OrderInfo.lastTime = block.timestamp;

        for (uint256 i; i < poolList.length; i++) {
            if (_orderId == poolList[i].orderId) {
                poolList[i] = OrderInfo;
            }
        }

        for (uint256 i; i < orderList.length; i++) {
            if (_orderId == orderList[i].orderId) {
                orderList[i] = OrderInfo;
            }
        }

        RREWARD_TOKEN.transfer(_msgSender(), OrderInfo.rewardAmount);

        emit Claimed(_orderId, OrderInfo.rewardAmount);
    }

    function claimAll() external checkStakingState checkUserIsStaked(_msgSender()){
        UserStakingTotalInfo memory TotalInfo = getUserStakingTotalInfo();
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];

        for (uint256 i; i < poolList.length; i++) {

            for (uint256 k; k < orderList.length; k++) {
                orderList[k].hadRewardAmount += _computeStakingRewardAmount(orderList[k]);
                if (orderList[k].endTime <= block.timestamp) {
                    orderList[k].rewardPerSecondToken = 0;
                }
                orderList[k].lastTime = block.timestamp;

                if(orderList[k].orderId == poolList[i].orderId){
                    poolList[i] = orderList[k];
                }
            }

            if (poolList[i].endTime <= block.timestamp){
                poolList[i].rewardPerSecondToken = 0;
            } 
        }

        userToTotalInfo[_msgSender()].hadRewardAmount += TotalInfo.rewardAmount; //history total add

        RREWARD_TOKEN.transfer(_msgSender(), TotalInfo.rewardAmount);

        emit ClaimedAll(TotalInfo.rewardAmount);
    }

//分批处理 返回下标。数组长度。
    function _settlementOfUsersRewards()private onlyOwner returns(bool){
        //需要分批处理
        for(uint i;i<poolList.length;i++){
            uint256 rewards = _computeStakingRewardAmount(poolList[i]);
            poolList[i].hadRewardAmount += rewards;
            userToTotalInfo[poolList[i].user].hadRewardAmount += rewards; //history total add

            // poolList[i].startingTime = block.timestamp;
            // poolList[i].endTime = block.timestamp + poolList[i].stakedDays.mul(60); //测试环境 分钟 * 60秒。 （min）正式需要* 86400秒
            poolList[i].apy = dayToApy[poolList[i].stakedDays];

            poolList[i].rewardPerSecondToken = poolList[i].stakedAmount * poolList[i].apy / 365 / 86400 / denominator * rewardRate; //结束前每秒的收益
            poolList[i].rewardPerSecondTokenAfter = poolList[i].stakedAmount * endApy / 365 / 86400 / denominator * rewardRate;

            poolList[i].lastTime = block.timestamp;

            if(poolList[i].endTime <= block.timestamp) {
                poolList[i].rewardPerSecondToken = 0;
                poolList[i].apy = endApy;
            }
            
            UserStakingInfo[] storage orderList = userToStakingList[poolList[i].user];

            for(uint k;k<orderList.length;k++){
                if(orderList[k].orderId == poolList[i].orderId){
                    orderList[k] = poolList[i];
                    userToCurrtentStaking[poolList[i].user][poolList[i].orderId] = poolList[i];
                }
            }
            RREWARD_TOKEN.transfer(poolList[i].user, rewards);
        }
        return true;
    }

    /* ========= OVERRIDE ======== */

    function setApys(uint16[5] memory _apys) external  onlyOwner returns(bool){
        stakingApys=_apys;
        dayToApy[30] = stakingApys[0];
        dayToApy[60] = stakingApys[1];
        dayToApy[90] = stakingApys[2];
        dayToApy[120] = stakingApys[3];
        dayToApy[150] = stakingApys[4];

        _settlementOfUsersRewards();
        return true;
    }

    function setRewardRate(uint32 _rate) external  onlyOwner returns(bool){
        rewardRate = _rate;
        _settlementOfUsersRewards();
        return true;
    }

    function setEndRate(uint32 _rate) external  onlyOwner returns(bool){
        endApy = _rate;
        _settlementOfUsersRewards();
        return true;
    }

    /* ========= OVERRIDE ======== */

    function getStakedLPBlanceOf() external view returns (uint256) {
        return LP_TOKEN.balanceOf(address(this));
    }
    function _getUsersTotalRewards() private view returns (uint256){
        uint256 totalRewards;
        for (uint256 i; i < poolList.length; i++) {
            totalRewards += _computeStakingRewardAmount(poolList[i]);
        }
        return totalRewards;
    }

    function getRemainingReward() external view returns (uint256) {
        uint256 total = RREWARD_TOKEN.balanceOf(address(this));
        return total.sub(_getUsersTotalRewards()); //需要 减去 可领取的。
    }

    function getPoolAllList() external view returns (UserStakingInfo[] memory orderList) {
        orderList = poolList;
        for (uint256 i = 0; i < poolList.length; i++) {
            orderList[i].rewardAmount = _computeStakingRewardAmount(orderList[i]);
            if (orderList[i].endTime <= block.timestamp) {
                orderList[i].apy = endApy;
            }
        }
        return orderList;
    }

    function getUserStakingTotalInfo() public view returns(UserStakingTotalInfo memory TotalInfo){
        UserStakingInfo[] memory orderList = userToStakingList[_msgSender()];
        TotalInfo = userToTotalInfo[_msgSender()];

        for(uint i=0;i<orderList.length;i++){
           TotalInfo.rewardAmount += _computeStakingRewardAmount(orderList[i]);
        }
        return TotalInfo;
    }

    function getUserCurrentAllStakingOrder() external view returns (UserStakingInfo[] memory orderList){
        orderList = userToStakingList[_msgSender()];
        for (uint256 i = 0; i < orderList.length; i++) {
            orderList[i].rewardAmount = _computeStakingRewardAmount(orderList[i]);
            if (orderList[i].endTime <= block.timestamp) {
                orderList[i].apy = endApy;
            }
        }
        return orderList;
    }

    /* 10 公式： 日收益 = 质押数量 * 日收益率 * 收益系数 */
    function _computeStakingRewardAmount(UserStakingInfo memory _OrderInfo) private view returns (uint256){
        uint256 callTime;//提现时间 、 挖矿结束时间
        uint256 startingAmount; //到期之前的收益
        uint256 afterAmount; //到期之后的收益

        isStopStaking == false? callTime = block.timestamp:callTime=lastStakingTime;

        if (_OrderInfo.endTime > block.timestamp) {
            if (_OrderInfo.hadRewardAmount > 0) {
                startingAmount = (callTime - _OrderInfo.lastTime).mul( _OrderInfo.rewardPerSecondToken);
            } else {
                startingAmount = (callTime - _OrderInfo.startingTime).mul(_OrderInfo.rewardPerSecondToken);
            }
            return startingAmount;
        } else {
            if (_OrderInfo.hadRewardAmount > 0) {
                afterAmount = (callTime - _OrderInfo.lastTime).mul(
                    _OrderInfo.rewardPerSecondTokenAfter
                );
            } else {
                startingAmount = (_OrderInfo.endTime - _OrderInfo.startingTime)
                    .mul(_OrderInfo.rewardPerSecondToken);
                afterAmount = (callTime - _OrderInfo.endTime).mul(
                    _OrderInfo.rewardPerSecondTokenAfter
                );
            }
            return startingAmount.add(afterAmount);
        }
    }
    /*========== EVENTS =========*/
    event Staked(uint16 _days, uint256 _LP_TOKEN);
    event Withdrawed(uint32 _orderId, uint256 _LP_TOKEN, uint256 _RREWARD_TOKEN);
    event Claimed(uint32 _orderId, uint256 _RREWARD_TOKEN);
    event ClaimedAll(uint256 _RREWARD_TOKEN);
}
