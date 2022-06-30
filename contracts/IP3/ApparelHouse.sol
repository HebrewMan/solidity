// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IIP3Protocol.sol";


contract IP3Appare is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint16 public fee_to_holder= 50;//5%

    uint16 public fee_to_designer = 100;//10%

    uint16 public fee_to_this = 25;//2.5%

    uint16 immutable denominator = 1000;

    bool private _withdraw_locked;

    mapping(string => DerivativesInfo) uriToDerivativesInfo;//tokenIds 

    struct DerivativesInfo{
        uint price;
        uint256[] cardTokenIds;
    }

    constructor() ERC721("IP3Appare ", "NFTIP3") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /** ---- overrides ----- */ 

    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    /** =========== CONFIG ========== */

    function setFeeForHolder(uint16 _newFee)external onlyOwner returns(uint16){
      return  fee_to_holder = _newFee*10;
    }

    function setFeeForThis(uint16 _newFee)external onlyOwner returns(uint16){
      return  fee_to_this = _newFee*10;
    }

    function setFeeForDesigner(uint16 _newFee)external onlyOwner returns(uint16){
      return  fee_to_designer = _newFee*10;
    }


    function withdraw() external onlyOwner {
        require(!_withdraw_locked, "reentrant call detected");
        _withdraw_locked = true;

        uint256 amount = address(this).balance;
        Address.sendValue(payable(msg.sender), amount);

        (bool success,) = address(this).call{value: amount}("");
        require(success, "Designer: Failed to send Ether");

        _withdraw_locked = false;
    }

    function makeDerivatives(string memory _uri,uint _price,uint256[] memory _cardTokenIds) external returns(DerivativesInfo memory){
        uriToDerivativesInfo[_uri].price = _price;
        uriToDerivativesInfo[_uri].cardTokenIds = _cardTokenIds;
        return uriToDerivativesInfo[_uri];
    }


    function mintDerivatives(string memory _uri)external payable{

        DerivativesInfo memory _DerivativesInfo = uriToDerivativesInfo[_uri];

        IERC721 Card = IERC721(0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1);

        IIP3Protocol IP3Protocol = IIP3Protocol(0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1);

        address holder = IP3Protocol.authorizeOf(_DerivativesInfo.cardTokenIds[0]).makerAddress; //藏家
        address designer = Card.ownerOf(_DerivativesInfo.cardTokenIds[0]);//设计师

        require(msg.value>=_DerivativesInfo.price,"AppareHouse: Below derivatives prices");

        Asset memory _Asset;
        _Asset.assetAddress = address(this);
        _Asset.tokenId = _tokenIdCounter.current();
        IP3Protocol.attach(_Asset,uriToDerivativesInfo[_uri].cardTokenIds);
        //雷康 燃烧
        //用户把 cards 授权给主合约 

        safeMint(_msgSender(),_uri);

        uint fee_total = msg.value;

        (bool success1, ) = holder.call{value: fee_total * fee_to_holder / denominator}("");
        require(success1, "Holder: Failed to send Ether");

        (bool success2, ) = designer.call{value: fee_total * fee_to_designer / denominator}("");
        require(success2, "Designer: Failed to send Ether");

        (bool success3, ) = address(this).call{value: fee_total * fee_to_this / denominator}("");
        require(success3, "AppareHouse: Failed to send Ether");

    }

    /*
        1.atach burn card
        2. 合约里 burn card
    */

    receive() external payable {}

}