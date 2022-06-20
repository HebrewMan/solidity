/**
 *Submitted for verification at BscScan.com on 2020-09-22
*/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ExchangeNFT {

    using SafeERC20 for IERC20;

    IERC20  public OBNB = IERC20(0x68480c29d3FFb49F73BA71713b0940d905A72D25);
    IERC721  public Orihero = IERC721(0xD2057AA91971F0DB84fBFB0d3877033F9300a77e);

    address private _owner;

    address public recNftAddr = 0x16e01fBd9e319FdE44142b26B7986d136e759077;//owner
    address public recObnbAddr = 0x16e01fBd9e319FdE44142b26B7986d136e759077;//test1
    uint256 public transferFee = 0.003e18;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender,"Ownable: caller is not the owner");
        _;
    }

    function setRecNftAddress (address _newRecNftAddr) public onlyOwner{
        recNftAddr = _newRecNftAddr;
        emit SetedRecNftAddress(recNftAddr,true);
    }

    function setRecObnbAddress (address _newRecObnbAddr) public onlyOwner{
        recObnbAddr = _newRecObnbAddr;
        emit SetedRecObnbAddress(recObnbAddr,true);
    }

    function exchange(address _to, uint32 _tokenId) external {
        require(Orihero.isApprovedForAll(msg.sender, address(this))==true, "User's nfts is not approve to this contract.");
        require(OBNB.allowance(msg.sender, address(this)) >= transferFee, "Insufficient number of users approved to this contract.");
        require(OBNB.balanceOf(msg.sender) >= transferFee, "Insufficient handling fee.");

        OBNB.transferFrom(msg.sender,recObnbAddr, transferFee);
        Orihero.safeTransferFrom(msg.sender,recNftAddr,_tokenId);
        emit ExchangedNft(msg.sender, _to, _tokenId);
        emit ExchangedObnb(msg.sender, recObnbAddr, transferFee);
    }

    /* ========== EVENTS ========== */
    event SetedRecNftAddress(address _newAddress,bool status);
    event SetedRecObnbAddress(address _newAddress,bool status);
    event ExchangedNft(address _from, address _to, uint32 _tokenId);
    event ExchangedObnb(address _from, address _to, uint256 _amount);

}

