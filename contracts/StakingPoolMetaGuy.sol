//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract StakingPoolAFICLP is Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC721 public NFT = IERC721(0xd75175E535b8b62e0C60B55B137971399fbe3FbC);
    IERC20 public AFIC = IERC20(0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD);
    IERC20 public GEE = IERC20(0x0F1867D0681F618c00d3Eeba563ce75ABDcbDEdD);

    mapping (address => mapping( uint8 => OrderInfo )) public userToIdToOrder;

    OrderInfo[] private _Orders;

    struct OrderInfo {
        address user;
        uint8 orderId; // 订单id type
        uint256 price;
        uint256 stakedDays; //质押类型 多少天（测试环境 分钟）
        uint256 endTime; //质押结束时间
        uint256 rewardAmount; //可领取的收益  当前订单 有多少收益（需要mapping解决）
        uint256[] stakedNFTs; //质押nft 数量
    }

    function stake(uint256 _price,uint8 _id,uint256 _days, uint256[] memory _tokenIds)external{
        require(AFIC.balanceOf(_msgSender())>=1000*1e8,"AFIC: Your AFIC token is below 1000");
        require(_tokenIds.length>0,"tokenIds is null");
        require(10>_id && _id>0,"Stake type error");

        OrderInfo memory _OrderInfo;

        _OrderInfo.user = _msgSender();
        _OrderInfo.price = _price;
        _OrderInfo.endTime = block.timestamp + _days.mul(60); //测试环境 分钟 * 60秒。 （min）正式需要 *30* 86400秒
        _OrderInfo.stakedDays = _days;
        //rewards 1000 * 10 * 3 * 85% = 25500 GEE ：GEE 收益 = 1000 *（AUC价格 / GEE价格）* 收益倍数  收益：用户到账85%，销毁15%
        _OrderInfo.rewardAmount = 1000*_price*(_id+1)*85/100;
        _OrderInfo.stakedNFTs = _tokenIds;

        _Orders.push(_OrderInfo);
        userToIdToOrder[_msgSender()][_id] = _OrderInfo;

        for(uint i;i<_tokenIds.length;i++){
            require(NFT.ownerOf(_tokenIds[i]) == _msgSender(),"The nft does not belong to msgSender");
            NFT.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }

        AFIC.safeTransferFrom(_msgSender(), address(0), 1000*1e8);
        
    }

    function unStake(uint8 _orderId) external {
        OrderInfo storage _OrderInfo = userToIdToOrder[_msgSender()][_orderId];
        require(_msgSender() == _OrderInfo.user,"The caller is not the owner of the order");
        require(GEE.balanceOf(address(this))>_OrderInfo.rewardAmount,"This pool GEE token is below");

        for(uint i;i<_OrderInfo.stakedNFTs.length;i++){
            NFT.safeTransferFrom(address(this), _OrderInfo.user, _OrderInfo.stakedNFTs[i]);
        }

        for (uint256 i; i < _Orders.length; i++) {
            if (_orderId == _Orders[i].orderId) {
                _Orders[i] = _Orders[_Orders.length - 1];
                _Orders.pop();
            }
        }

        GEE.safeTransfer(_msgSender(),  _OrderInfo.rewardAmount);
        
        delete userToIdToOrder[_msgSender()][_orderId];
    }

    function getAllStakingList()external view returns(OrderInfo[] memory){
        return _Orders;
    }
         
}
