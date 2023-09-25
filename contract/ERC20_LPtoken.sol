// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPtoken is ERC20{
    
    address public owner;
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can use");
        _;
    }

    constructor() ERC20("lptoken", "lpt"){
        owner = msg.sender;
    }

    function mint(address account,uint amount) public onlyOwner{
        _mint(account,amount);
    }

    function burn(address account,uint amount) public onlyOwner{
        _burn(account,amount);
    }   
}