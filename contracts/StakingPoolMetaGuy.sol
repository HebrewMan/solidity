//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
contract StakingPoolMetaGuy is Ownable,ERC721Holder{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC721 public NFT = IERC721(0x50B7F926D06dD860ee40dBE25A5E9Ecd906608C6);
    IERC20 public AUC = IERC20(0x3e0aDEb80331e26cF38aF17D6E638fCEB3BA455c);
    IERC20 public GEE = IERC20(0x942647E070c5D7ADcaB2Fc6a952Abb1EF9066966);

    address internal immutable deadAddr = 0x000000000000000000000000000000000000dEaD;

    mapping (address => mapping( uint8 => OrderInfo )) public userToIdToOrder;

    mapping (address => OrderInfo[]) internal userToOrders;

    OrderInfo[] private _PoolOrders;

    struct OrderInfo {
        address user;
        uint8 orderId; // 订单id type
        uint256 price;
        uint256 endTime; //质押结束时间
        uint256 rewardAmount; //可领取的收益  当前订单 有多少收益（需要mapping解决）
        uint256[] stakedNFTs; //质押nft 数量
    }
    
    function stake(uint256 _price,uint8 _id, uint256[] memory _tokenIds)external{
        require(AUC.balanceOf(_msgSender())>=1000*1e8,"AUC: Your AUC token is below 1000");
        require(_tokenIds.length>0,"TokenIds is null");
        require(_tokenIds.length == _id,"TokenId does not match the pledge type");
        require(10>_id && _id>0,"No such pledge type");
        require(userToIdToOrder[_msgSender()][_id].endTime<=0,"This type of order already exists");

        OrderInfo memory _OrderInfo;

        _OrderInfo.user = _msgSender();
        _OrderInfo.price = _price;
        _OrderInfo.orderId = _id;
        _OrderInfo.endTime = block.timestamp + 30*60; //测试环境 分钟 * 60秒。 （min）正式需要 *30* 86400秒
        _OrderInfo.rewardAmount = 1000*(_id+1)*_price;
        _OrderInfo.stakedNFTs = _tokenIds;

        _PoolOrders.push(_OrderInfo);
        userToOrders[_msgSender()].push(_OrderInfo);
        userToIdToOrder[_msgSender()][_id] = _OrderInfo;

        for(uint i;i<_tokenIds.length;i++){
            require(NFT.ownerOf(_tokenIds[i]) == _msgSender(),"The nft does not belong to msgSender");
            NFT.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }

        AUC.safeTransferFrom(_msgSender(),address(this),1000*1e8);
    
    }

    function unStake(uint8 _orderId) external {
        OrderInfo storage _OrderInfo = userToIdToOrder[_msgSender()][_orderId];
        OrderInfo[] storage UserOrders = userToOrders[_msgSender()];
        require(_msgSender() == _OrderInfo.user,"The caller is not the owner of the order");
        require(GEE.balanceOf(address(this))>_OrderInfo.rewardAmount,"This pool GEE token is below");
        require(_OrderInfo.endTime<=block.timestamp,"The current order has not expired");

        for(uint i;i<_OrderInfo.stakedNFTs.length;i++){
            NFT.safeTransferFrom(address(this), _msgSender(), _OrderInfo.stakedNFTs[i]);
        }

        for (uint256 i; i < _PoolOrders.length; i++) {
            if(_PoolOrders[i].user == _msgSender()){
                if(_PoolOrders[i].orderId == _orderId){
                    _PoolOrders[i] = _PoolOrders[_PoolOrders.length - 1];
                    _PoolOrders.pop();
                } 
            }
        }

        for (uint256 i; i < UserOrders.length; i++) {
            if (UserOrders[i].orderId == _orderId) {
                UserOrders[i] = UserOrders[UserOrders.length - 1];
                UserOrders.pop();
            }
        }

        GEE.safeTransfer(_msgSender(),_OrderInfo.rewardAmount);

        AUC.safeTransfer(deadAddr,950*1e8);
        
        delete userToIdToOrder[_msgSender()][_orderId];
    }

    function getAllStakingList()external view returns(OrderInfo[] memory){
        return _PoolOrders;
    }

    function getUserStakingList()external view returns(OrderInfo[] memory){
        return userToOrders[_msgSender()];
    }

    function getUserTokenIds(address _user) public view returns(uint [] memory ) {
        IERC721Enumerable _NFT = IERC721Enumerable(0x50B7F926D06dD860ee40dBE25A5E9Ecd906608C6);

        uint length = NFT.balanceOf(_user);
        uint[] memory tokenIds = new uint[](length);

        for(uint i = 0; i< length; i++) {
            tokenIds[i] = _NFT.tokenOfOwnerByIndex(_user,i);
        }
        return tokenIds;
    }
         
}
