// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract MyToken1155 is ERC1155, Ownable, ERC1155Supply,ERC1155Burnable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public name = "IP3 Authorization Card";
    
    uint8 public mintFee = 25;// ------ config ------

    uint16 private immutable _denominator = 1000;

    uint256 public maxMintAmount = 10000;// ------ config ------


    //nft 创建授权卡（信息）card照片平台提供 ==>获取当前Nft 的json url 图片 生成我们的card图片

    //设计师来mint授权卡

    //多张nft 创建授权卡

    //获取授权卡信息 给衍生品合约

    //授权卡 ID 获取 （原nft holder、）

    //??? 授权卡过期的问题 过期之后 没有被mint出来的怎么办。 过期之后 没有创作衍生品怎么办 
    //⬆️ 解决方案 当用户mint出来的时候 更新 CardInfo expired时间。 之前都是默认值

    //??? holder一个nft mint了两个授权卡 怎么办 解决方案 一个只能 创作一次。


    //衍生品合约 创作衍生品 关联信息（作者、价格、授权卡id）

    //衍生品合约关联 授权卡 mint 出衍生品时候 方便燃烧 （正确的）授权卡们


    address[] internal supportedNFTs;//Currently supported nfts.

    mapping(uint256 => string) private idToURI;

    mapping(uint => CardInfo) public cardIdToCardInfo;

    mapping(address => mapping (uint=>CardInfo)) public originNftToTokenIdToCardInfo;


    // struct OriginNFT {
    //     address addr;
    //     uint tokenId;
    // }

    struct CardInfo {
        address originAddr;
        address holder;
        uint originTokenId;
        uint price;
        uint amount;
        uint expiredTime;
        bool hasBeenMinted;
    }


    constructor() ERC1155("https://ip3.io/authorization/cards/{id}.json") {

        supportedNFTs.push(0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d);//Bored Ape Yacht Club
        supportedNFTs.push(0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d);//CryptoPunks 
        supportedNFTs.push(0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d);//Azuki

        // mint(msg.sender, CARDS_BAY, 100, ""); 
    }

    function setTokenUri(uint256 _tokenId,string memory _uri) public onlyOwner{
        idToURI[_tokenId] =  _uri;
    }

    // function setURI(string memory newuri) public onlyOwner {
    //     _setURI(newuri);
    // }

    function makeAuthorization(address _originAddr,uint _origintId, uint256 _price, uint256 _amount, uint _expiredTime)external payable {

        IERC721 _OriginNFT = IERC721(_originAddr);
        require(_msgSender() == _OriginNFT.ownerOf(_origintId),"");
        //_

        CardInfo storage _CardInfo = originNftToTokenIdToCardInfo[_originAddr][_origintId];

        //如果该tokenId 大于了10000张。一年之内不可创作授权卡 
        require(_CardInfo.amount<=maxMintAmount,"");
        _CardInfo.originAddr = _originAddr;
        _CardInfo.originTokenId = _origintId;
        _CardInfo.holder = _msgSender();
        _CardInfo.price = _price;
        _CardInfo.amount = _amount;
        _CardInfo.expiredTime = _expiredTime;

    }

    /**
        _OrigintId 前端获取
     */

    function mintAuthorization(address _originAddr,uint _origintId,uint _amount)external payable{
        //检查_originAddr 是否在 支持nft列表里
        //分红2.5%
        //检查 价格 和 msg.value

        originNftToTokenIdToCardInfo[_originAddr][_origintId].hasBeenMinted = true;
        uint time = originNftToTokenIdToCardInfo[_originAddr][_origintId].expiredTime;
        originNftToTokenIdToCardInfo[_originAddr][_origintId].expiredTime += time;

        uint256 cardTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        mint(_msgSender(),cardTokenId,_amount,"");

        cardIdToCardInfo[cardTokenId] = originNftToTokenIdToCardInfo[_originAddr][_origintId];//方便给衍生品合约调用

        address holder = originNftToTokenIdToCardInfo[_originAddr][_origintId].holder;
        
        (bool success, ) = payable(holder).call{value: msg.value * (1000 - mintFee) / _denominator}("");
        require(success, "Holder: Failed to send Ether");

        // cardIdToOriginNft[cardTokenId].addr = _originAddr;
        // cardIdToOriginNft[cardTokenId].tokenId = _origintId;

    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) internal{   
        string memory tokenIdUri = string(abi.encodePacked(Strings.toString(id), ".json"));
        tokenIdUri = string.concat("https://ip3.io/authorization/cards/",tokenIdUri);
        idToURI[id] = tokenIdUri;
        _mint(account, id, amount, data);
    }

    // ============= onlyOwner ===============

    function withdraw() external onlyOwner{
        (bool sent, ) = _msgSender().call{value: address(this).balance }("");
        require(sent, "sent: Failed2 to send Ether");
    }

    function setMintFee(uint8 _fee)external onlyOwner{
        mintFee = _fee;
    }

    function setMaxMintAmount(uint _amount)external onlyOwner{
        maxMintAmount = _amount;
    }

    function addItemToSupportedNFTs(address _nftAddr) external onlyOwner{
        supportedNFTs.push(_nftAddr);
    }

    function deleteItemforSupportedNFTs(address _nftAddr) external onlyOwner{

        for (uint256 i; i < supportedNFTs.length; i++) {
            if (_nftAddr == supportedNFTs[i]) {
                supportedNFTs[i] = supportedNFTs[supportedNFTs.length - 1];
                supportedNFTs.pop();
            }
        }

    }

    // ======== get =======

    function getOriginNftMakedInfo(address _addr,uint _tokenId) external view returns(CardInfo memory){
        return originNftToTokenIdToCardInfo[_addr][_tokenId];
    }

    function getSupportedNFTs() public view returns(address[] memory){
        return supportedNFTs;
    }

    function getCardInfo (uint _tokenId)public view returns(CardInfo memory){
        return cardIdToCardInfo[_tokenId];
    }

    // ================ overrides =================
    
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return idToURI[_tokenId];
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //jljlk

    receive() external payable {}

  
}
