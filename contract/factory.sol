// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 
import "./ERC20_LPtoken.sol";

contract LptokenFactory{

    mapping (address => mapping(address => address)) public LptoakePair;
    address[] public LptokenAddressList;
    LPtoken public lpToken;
    address public LPtokenAddress;
    address public funcLPtokenAddress;


    function createLptokenPair(address token0, address token1) public {
        bytes32 _salt = keccak256(
            abi.encodePacked(
                token0, token1
            )
        );
        lpToken = new LPtoken{
            salt:bytes32(_salt)
        }();
        funcLPtokenAddress = createLptokenAddress(_salt);
        LPtokenAddress = address(lpToken);
        LptoakePair[token0][token1] = LPtokenAddress;
        LptoakePair[token1][token0] = LPtokenAddress;
        LptokenAddressList.push(LPtokenAddress);
    }
    //示範如何計算地址
    function createLptokenAddress(bytes32 _salt) internal view returns(address) {
        bytes memory bytecode = getBytecode();
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), _salt, keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }

    function getBytecode() internal pure returns(bytes memory){
        bytes memory bytecode = type(LPtoken).creationCode;
        return bytecode;
    }
    
}
