// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC20_LPtoken.sol";

contract AMM{
    //第一個address是LPtoken地址 第二個地址是池子代幣資產量
    mapping (address => mapping(address => uint)) public reserve;
    //查詢對應的LPtoken地址
    mapping (address => mapping(address => address)) public checkLPtokenAddress;
    //LPtoken地址列
    address [] public LPtokenAddressList;
    //項目方的錢包地址
    address public immutable owner;
    //項目方增發LPtoken數量紀錄
    mapping (address => uint) public checkLPtokenOwner;
    //增加流動性
    event AddLiquidity(address token0, address token1, uint token0_amount, uint token1_amount);
    //減少流動性
    event MinusLiquidity(address token0, address token1, uint token0_amount, uint token1_amount);
    //兌換
    event Swap(address tokenIn, address tokenOut, uint amountIn, uint amountOut);
    //執行增發
    event MintLPtokenForOwner(uint shares);

    constructor(){
        owner = msg.sender;
    }
    //只有創建者才能使用
    modifier onlyOwner{
        require(msg.sender == owner,"Only owner can use");
        _;
    }
    //建立池子
    function createLptokenPair(address token0, address token1) private returns(address){
        bytes32 _salt = keccak256(
            abi.encodePacked(
                token0, token1
            )
        );
        LPtoken lpToken = new LPtoken{
            salt:bytes32(_salt)
        }();
        address LPtokenAddress = address(lpToken);
        //添加LPtoken地址
        checkLPtokenAddress[token0][token1] = LPtokenAddress;
        checkLPtokenAddress[token1][token0] = LPtokenAddress;
        LPtokenAddressList.push(LPtokenAddress);
        return LPtokenAddress;
    }
    //添加流動性
    function addLiquidity (address _token0, address _token1, uint _amount0, uint _amount1)
        external
        returns (uint shares){
        require(_token0 != address(0) && _token1 != address(0),"Address can not be 0x00");
        require(_token0 != _token1,"Address can not be the same");
        //確認池子對是否已存在
        if(checkLPtokenAddress[_token0][_token1] == address(0) && checkLPtokenAddress[_token1][_token0] == address(0)){
            //創建新池子對的LPtoken地址
            address LPtokenAddress = createLptokenPair(_token0, _token1);
            LPtoken lpTokenInstance = LPtoken(LPtokenAddress);
            //轉移ERC20
            ERC20 token0 = ERC20(_token0);
            ERC20 token1 = ERC20(_token1);
            token0.transferFrom(msg.sender, address(this), _amount0);
            token1.transferFrom(msg.sender, address(this), _amount1);
            //添加池子
            reserve[LPtokenAddress][_token0] += _amount0;
            reserve[LPtokenAddress][_token1] += _amount1;
            //返回獎勵
            shares = _sqrt(_amount0 * 1e8 * _amount1 * 1e8);
            //鑄造獎勵代幣
            lpTokenInstance.mint(msg.sender,shares);
        }else{
            //LPtoken的地址
            address LPtokenAddress = checkLPtokenAddress[_token1][_token0];
            LPtoken lpTokenInstance = LPtoken(LPtokenAddress);
            //LPtoken的總數量
            uint totalSupply = lpTokenInstance.totalSupply();
            //限制投入比例
            uint reserve0 = reserve[LPtokenAddress][_token0];
            uint reserve1 = reserve[LPtokenAddress][_token1];
            require(_amount1 * reserve0 == _amount0 * reserve1,"Investment is not proportional");
            //轉移ERC20
            ERC20 token0 = ERC20(_token0);
            ERC20 token1 = ERC20(_token1);
            token0.transferFrom(msg.sender, address(this), _amount0);
            token1.transferFrom(msg.sender, address(this), _amount1);
            //添加池子
            reserve[LPtokenAddress][_token0] += _amount0;
            reserve[LPtokenAddress][_token1] += _amount1;
            //返回獎勵
            shares = (_amount0 * 1e8 * totalSupply)/reserve0;
            //鑄造獎勵代幣
            lpTokenInstance.mint(msg.sender,shares);
        }
        emit AddLiquidity(_token0, _token1, _amount0, _amount1);
    }
    //減少流動性
    function minusLiquidity (address _token0, address _token1, uint _amountLp) 
        external 
        returns (uint _amount0, uint _amount1){
        require(_token0 != address(0) && _token1 != address(0),"Address can not be 0x00");
        require(_token0 != _token1,"Address can not be the same");
        //LPtoken池子地址
        address LPtokenAddress = checkLPtokenAddress[_token0][_token1];
        LPtoken lpTokenInstance = LPtoken(LPtokenAddress);
        //LPtoken的總數量
        uint totalSupply = lpTokenInstance.totalSupply();
        //返回數量
        uint reserve0 = reserve[LPtokenAddress][_token0];
        uint reserve1 = reserve[LPtokenAddress][_token1];
        _amount0 = (_amountLp * reserve0) / totalSupply;
        _amount1 = (_amountLp * reserve1) / totalSupply;
        //轉移ERC20
        ERC20 token0 = ERC20(_token0);
        ERC20 token1 = ERC20(_token1);
        token0.transfer(msg.sender, _amount0);
        token1.transfer(msg.sender, _amount1);
        //減少池子
        reserve[LPtokenAddress][_token0] -= _amount0;
        reserve[LPtokenAddress][_token1] -= _amount1;
        //燒毀LPtoken
        lpTokenInstance.burn(msg.sender, _amountLp);
        emit MinusLiquidity(_token0, _token1, _amount0, _amount1);
    }
    //兌換
    function swap (address _tokenIn, address _tokenOut, uint _amountIn) 
        external 
        returns (uint _amountOut){
        require(_tokenIn != address(0) && _tokenOut != address(0),"Address can not be 0x00");
        require(_tokenIn != _tokenOut,"Address can not be the same");
        //LPtoken池子地址
        address LPtokenAddress = checkLPtokenAddress[_tokenIn][_tokenOut];
        //返回數量
        uint reserveIn = reserve[LPtokenAddress][_tokenIn];
        uint reserveOut = reserve[LPtokenAddress][_tokenOut];
        //原始流動性
        uint k = reserveIn * reserveOut;
        //扣除手續費
        uint _newAmountIn = (_amountIn * 997) / 1000;
        //計算換出量
        _amountOut = (_newAmountIn * reserveOut) / (_newAmountIn + reserveIn); 
        //轉移ERC20
        ERC20 token0 = ERC20(_tokenIn);
        ERC20 token1 = ERC20(_tokenOut);
        token0.transferFrom(msg.sender, address(this), _amountIn);
        token1.transfer(msg.sender, _amountOut);
        //池內數量調整
        reserve[LPtokenAddress][_tokenIn] += _amountIn;
        reserve[LPtokenAddress][_tokenOut] -= _amountOut;
        //執行增發代幣
        caculateFee(LPtokenAddress, _tokenIn, _tokenOut, k);
        emit Swap(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }
    //計算手續費並紀錄
    function caculateFee (address LPtokenAddress, address _tokenIn, address _tokenOut, uint k) private returns(uint){
        //返回數量
        uint reserve0 = reserve[LPtokenAddress][_tokenIn];
        uint reserve1 = reserve[LPtokenAddress][_tokenOut];
        //新的流動性
        uint newK = reserve0 * reserve1;
        //增發數量
        ERC20 LP = ERC20(LPtokenAddress);
        uint totalSupply = LP.totalSupply();
        uint sm = ((_sqrt(newK) - _sqrt(k)) * totalSupply) / ((5 * _sqrt(newK)) + _sqrt(k));
        //紀錄獎勵代幣
        checkLPtokenOwner[LPtokenAddress] += sm;
        return sm;
    }
    //執行增發獎勵
    function mintLPtokenForOwner (address LPtokenAddress) public onlyOwner(){
        //取得增發獎勵
        uint sm = checkLPtokenOwner[LPtokenAddress];
        //鑄造獎勵代幣
        LPtoken lpTokenInstance = LPtoken(LPtokenAddress);
        lpTokenInstance.mint(owner,sm);
        //減去發行數量
        checkLPtokenOwner[LPtokenAddress] -= sm;
        emit MintLPtokenForOwner(sm);
    }
    //計算滑點
    function caculateSlip (uint dx, uint x, uint y) external pure returns (uint new_dy, uint dy, uint ans){
        new_dy = dx * y / (x + dx);
        dy = dx * y / x;
        uint slip = new_dy * 1e4 / dy;
        ans = 1e4 - slip;
        return (new_dy,dy,ans);
    }
    //計算兌換
    function caculateAmountOut (uint _amountIn, uint _reserveIn, uint _reserveOut) external pure returns (uint){
        return _reserveOut * _amountIn / (_amountIn + _reserveIn);
    }
    //開根號函式
    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}