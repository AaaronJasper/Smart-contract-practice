// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //總發行量
    function totalSupply() external view returns (uint256);

    //查詢餘額
    function balanceOf(address account) external view returns (uint256);
    //授權餘額查詢
    function allowance(address owner, address spender) external view returns (uint256);
    
    //授權函式
    function approve(address spender, uint256 amount) external returns (bool);
    //轉帳
    function transfer(address to, uint256 amount) external returns (bool);
    //授權轉帳
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20 is IERC20{

    string _name;
    string _symbol;
    uint _totalSupply ;
    address _owner;
    mapping (address => uint) _balance;
    mapping (address => mapping(address => uint)) _allowance;

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _totalSupply = 10000;
        _balance[msg.sender] = 10000;
    }

    function mint(address account, uint amount) public {
        require(_owner == msg.sender, "only owner can");
        require(account != address(0), "account can not be 0");
        _balance[account] += amount;
        emit Transfer(address(0),account, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256){
        return _balance[account];
    }

    function transfer(address to, uint256 amount) public returns (bool){
        require(_balance[msg.sender] >= amount, "not enought money");
        require(to != address(0), "address can not be 0");
        _balance[msg.sender] -= amount;
        _balance[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool){
        require(_balance[msg.sender] >= amount, "not enough money");
        _allowance[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool){
        require(_balance[from] >= amount, "not enough money");
        require(_allowance[from][msg.sender] >= amount, "not enough money");
        uint allowanceMoney =_allowance[from][msg.sender];
        _allowance[from][msg.sender] = allowanceMoney - amount;
        emit Approval(from, to, allowanceMoney);
        uint balanceMoney = _balance[from];
        _balance[from] = balanceMoney - amount;
        _balance[to] += amount;
        return true;
    }
}