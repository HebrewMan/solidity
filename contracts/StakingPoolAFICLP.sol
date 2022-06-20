//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract StakingPoolAFICLP is Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint16;

    bool public isStopStaking;
    uint256 internal stopStakingTime;
         
    uint32 internal counter = 0;//记录订单id
    uint8 internal denominator = 100;//分母用来计算

    IERC20 public constant LP_TOKEN = IERC20(0x40Be8dB1401b48B6B62C3ff4AB4c9aECB239ad60);//AFICLP
    IERC20 public constant RREWARD_TOKEN = IERC20(0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD);//AFIC

    uint256[4] internal stakingApys = [100000000,200000000,300000000,400000000];

    mapping(uint16 => uint256) public dayToApy;
 
    mapping(address => UserStakingInfo[]) internal userToStakingList; //address to all user's staking order.
    mapping(address => mapping(uint32 => UserStakingInfo)) internal userToCurrtentStaking; //address to current user staked info.
    mapping(address => UserStakingTotalInfo) internal userToTotalInfo;

    UserStakingInfo[] public poolList;

    constructor() {
        // dayToApy[1] = stakingApys[0];
        // dayToApy[3] = stakingApys[1];
        // dayToApy[6] = stakingApys[2];
        // dayToApy[12] = stakingApys[3];
        dayToApy[10] = stakingApys[0];
        dayToApy[20] = stakingApys[1];
        dayToApy[30] = stakingApys[2];
        dayToApy[40] = stakingApys[3];
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
        require(this.getRemainingReward() >= 100 * 1e8,"RREWARD_TOKEN: Pool balance is less than 100");
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
        uint256 apy; //当前收益率
        uint256 startingTime; //质押开始时间
        uint256 endTime; //质押结束时间
        uint256 lastTime; //最近一次更新的时间
        uint256 stakedAmount; //质押份额
        uint256 rewardAmount; //可领取的收益  当前订单 有多少收益
        uint256 hadRewardAmount; //已经领取的收益 当前订单 领取了多少收益（需要mapping解决）
        uint256 rewardPerSecondToken; //用户的每单位(秒) token 奖励数
    }

    function stake(uint16 _days, uint256 _amount) external checkPoolBlanceOf checkStakingState{
        counter++;
        UserStakingInfo memory OrderInfo;
        OrderInfo.user = _msgSender();
        OrderInfo.startingTime = block.timestamp;
        OrderInfo.endTime = block.timestamp + _days.mul(60); //测试环境 分钟 * 60秒。 （min）正式需要 *30* 86400秒
        OrderInfo.orderId = counter;

        OrderInfo.stakedDays = _days;
        OrderInfo.apy = dayToApy[_days];
        OrderInfo.stakedAmount = _amount; 

        OrderInfo.rewardPerSecondToken = _amount  * OrderInfo.apy / 365 / 86400 / denominator; //结束前每秒的收益

        poolList.push(OrderInfo);
        userToStakingList[_msgSender()].push(OrderInfo);
        userToCurrtentStaking[_msgSender()][OrderInfo.orderId] = OrderInfo;
        userToTotalInfo[_msgSender()].stakedAmount += _amount;

        LP_TOKEN.safeTransferFrom(_msgSender(), address(this), _amount);

        emit Staked(_days, _amount);
    }

    function withdraw(uint32 _orderId) external checkOrderIsExist(_orderId) {
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];
        UserStakingInfo memory OrderInfo = userToCurrtentStaking[_msgSender()][_orderId];

        require(isStopStaking == true|| OrderInfo.endTime<=block.timestamp,"StakingPool: Does not meet the release conditions");

        uint256 rewardAmount = _computeStakingRewardAmount(OrderInfo);
        userToTotalInfo[_msgSender()].hadRewardAmount += rewardAmount;

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

        if(rewardAmount>0){
            RREWARD_TOKEN.safeTransfer(_msgSender(), rewardAmount);
        }

        LP_TOKEN.safeTransfer(_msgSender(), OrderInfo.stakedAmount);

        delete userToCurrtentStaking[_msgSender()][_orderId];

        emit Withdrawed(_orderId,OrderInfo.stakedAmount,rewardAmount);
    }

    function claim(uint32 _orderId) external checkOrderIsExist(_orderId) checkStakingState{
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];
        UserStakingInfo storage OrderInfo = userToCurrtentStaking[_msgSender()][_orderId];

        uint256 rewardAmount = _computeStakingRewardAmount(OrderInfo);
        OrderInfo.hadRewardAmount += rewardAmount;
        userToTotalInfo[_msgSender()].hadRewardAmount += rewardAmount;

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

        RREWARD_TOKEN.safeTransfer(_msgSender(), rewardAmount);

        emit Claimed(_orderId, rewardAmount);
    }

    function claimAll() external checkUserIsStaked(_msgSender()) checkStakingState{
        UserStakingTotalInfo memory TotalInfo = getUserStakingTotalInfo();
        UserStakingInfo[] storage orderList = userToStakingList[_msgSender()];

        for (uint256 i; i < poolList.length; i++) {

            for (uint256 k; k < orderList.length; k++) {
                orderList[k].hadRewardAmount += _computeStakingRewardAmount(orderList[k]);
                orderList[k].lastTime = block.timestamp;
                
                userToCurrtentStaking[_msgSender()][orderList[k].orderId] = orderList[k];

                if(orderList[k].orderId == poolList[i].orderId){
                    poolList[i] = orderList[k];
                }
            }

        }

        userToTotalInfo[_msgSender()].hadRewardAmount += TotalInfo.rewardAmount; //history total add

        RREWARD_TOKEN.safeTransfer(_msgSender(), TotalInfo.rewardAmount);

        emit ClaimedAll(TotalInfo.rewardAmount);
    }

    function adminRewardWithdraw(uint256 amount) external onlyOwner {
        RREWARD_TOKEN.safeTransfer(msg.sender, amount);
    }

     function _settlementOfUsersRewards()private onlyOwner returns(bool){
        //需要分批处理
        for(uint i;i<poolList.length;i++){
            uint256 rewards = _computeStakingRewardAmount(poolList[i]);
            poolList[i].hadRewardAmount += rewards;
            userToTotalInfo[poolList[i].user].hadRewardAmount += rewards; //history total add
            poolList[i].apy = dayToApy[poolList[i].stakedDays];
            poolList[i].rewardPerSecondToken = poolList[i].stakedAmount * poolList[i].apy  / 365 / 86400 / denominator; //结束前每秒的收益

            poolList[i].lastTime = block.timestamp;

            // if(poolList[i].endTime <= block.timestamp) {
            //     poolList[i].rewardPerSecondToken = 0;
            // }
            
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

    function setApys(uint256[4] memory _apys) external  onlyOwner returns(bool){
        stakingApys=_apys;
        // dayToApy[1] = stakingApys[0];
        // dayToApy[3] = stakingApys[1];
        // dayToApy[6] = stakingApys[2];
        // dayToApy[12] = stakingApys[3];
        dayToApy[10] = stakingApys[0];
        dayToApy[20] = stakingApys[1];
        dayToApy[30] = stakingApys[2];
        dayToApy[40] = stakingApys[3];

        _settlementOfUsersRewards();
        return true;
    }

    function setStakingSwitch(bool _state) external onlyOwner returns(bool){
        isStopStaking = _state;
        stopStakingTime = block.timestamp;
        return true;
    }

    function getApys() external view returns(uint256[4] memory){
        return stakingApys;
    }

    function getPoolStakedTokenBlanceOf() external view returns (uint256) {
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
        if(total>_getUsersTotalRewards()){
            return total.sub(_getUsersTotalRewards()); //需要 减去 可领取的。
        }else{
            return 0;
        }
    }

    function getPoolAllList() external view returns (UserStakingInfo[] memory orderList) {
        orderList = poolList;
        for (uint256 i = 0; i < poolList.length; i++) {
            orderList[i].rewardAmount = _computeStakingRewardAmount(orderList[i]);
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
        }
        return orderList;
    }

    // function getItemOrder(uint32 _orderId)external view returns(UserStakingInfo memory){
    //     return userToCurrtentStaking[_msgSender()][_orderId];
    // }

    // function getItemOrderRewards(uint32 _orderId)external view returns(uint256){
    //     UserStakingInfo memory OrderInfo = userToCurrtentStaking[_msgSender()][_orderId];
    //     return _computeStakingRewardAmount(OrderInfo);
    // }

    /* 10 公式： 日收益 = 质押数量 * 日收益率 * 收益系数 */
    function _computeStakingRewardAmount(UserStakingInfo memory _OrderInfo) private view returns (uint256){
        uint256 RewardsAmount;
        uint256 callTime;
        uint256 computeTime;

        // isStopStaking == false? callTime = block.timestamp:callTime=stopStakingTime;

        if(isStopStaking == false){
            _OrderInfo.endTime <= block.timestamp? callTime = _OrderInfo.endTime : callTime = block.timestamp;
        }else{
            _OrderInfo.endTime < stopStakingTime? callTime = _OrderInfo.endTime : callTime = stopStakingTime;
        }

        _OrderInfo.hadRewardAmount > 0? computeTime =  _OrderInfo.lastTime : computeTime = _OrderInfo.startingTime;
        //lastTime > endTIme;
        if(computeTime>callTime){
            RewardsAmount = 0;
        }else{
            RewardsAmount = (callTime - computeTime).mul( _OrderInfo.rewardPerSecondToken);
        }

        return RewardsAmount/1e10;
    }
    /*========== EVENTS =========*/
    event Staked(uint16 _days, uint256 _LP_TOKEN);
    event Withdrawed(uint32 _orderId, uint256 _LP_TOKEN, uint256 _RREWARD_TOKEN);
    event Claimed(uint32 _orderId, uint256 _RREWARD_TOKEN);
    event ClaimedAll(uint256 _RREWARD_TOKEN);
}
