// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    // Event
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Query
    //查詢數量
    function balanceOf(address owner) external view returns (uint256 balance);
    //查詢擁有者
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // Transfer
    //安全帶資料轉移
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    //安全轉移
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    //普通轉移
    function transferFrom(address from, address to, uint256 tokenId) external;

    // Approve
    //單一授權
    function approve(address to, uint256 tokenId) external;
    //授權全部
    function setApprovalForAll(address operator, bool _approved) external;
    //查詢單一授權
    function getApproved(uint256 tokenId) external view returns (address operator);
    //查詢是否授權全部
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
contract ERC721 is IERC721, IERC165{

    mapping (address => uint) _balance;
    mapping (uint => address) _owner;
    mapping (uint => address) _approve;
    mapping (address => mapping(address => bool)) _approveAll;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool){
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) public view returns (uint256){
        require(owner != address(0),"Error address can not be 0");
        return _balance[owner];
    }
    function ownerOf(uint256 tokenId) public view returns (address){
        address owner = _owner[tokenId];
        require(owner != address(0),"Error address can not be 0");
        return owner;
    }
    function approve(address to, uint256 tokenId) public{
        address owner = _owner[tokenId];
        require(owner != to,"Error to == owner");
        require(owner == msg.sender ,"Error");
        _approve[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address){
        address owner = _owner[tokenId];
        require(owner != address(0),"Error owner can not be 0");
        return _approve[tokenId];
    }
    function setApprovalForAll(address operator, bool _approved) public{
        require(msg.sender != operator,"Error owner == poerator");
        _approveAll[msg.sender][operator]=_approved;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool){
        return _approveAll[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public{
        address owner =_owner[tokenId];
        require(owner == from ,"Error");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender,"Error");
        delete _approve[tokenId];
        _balance[from] -=1;
        _balance[to] +=1;
        _owner[tokenId]=to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data),"Error: ERC721Receiver is not implmeneted");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public{
        safeTransferFrom(from, to, tokenId, "");
    }

     function mint(address to, uint256 tokenId) public {
        require(to != address(0), "ERROR: Mint to address 0");
        address owner = _owner[tokenId];
        //檢查是否重複
        require(owner == address(0), "ERROR: tokenId existed");
        _balance[to] += 1;
        _owner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function safemint(address to, uint256 tokenId, bytes memory data) public {
        mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "ERROR: ERC721Receiver is not implmeneted");
    }

    function safemint(address to, uint256 tokenId) public {
        safemint(to, tokenId, "");
    }

    function burn(uint256 tokenId) public {
        address owner = _owner[tokenId];
        require(msg.sender == owner, "ERROR: only owner can burn");
        _balance[owner] -= 1;
        delete _owner[tokenId];
        delete _approve[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    // Reference Link: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol#L429-L451
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0 /* to is a contract*/) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}