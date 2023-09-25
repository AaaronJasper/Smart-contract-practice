// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 

contract swap_test{
    uint public reserve0;
    uint public reserve1;
    uint public totalSupply;
    mapping (address => uint) public userBalance;
    //計算兌換
    function caculateAmountOut (uint _amountIn, uint _reserveIn, uint _reserveOut) external pure returns (uint){
        return _reserveOut * _amountIn / (_amountIn + _reserveIn);
    }
    //兌換
    function swap0 (uint _amount0) external returns (uint _amount1){
        _amount1 = _amount0 * reserve1 / (_amount0 + reserve0);
        reserve0 += _amount0;
        reserve1 -= _amount1;       
    }
    function swap1 (uint _amount1) external returns (uint _amount0){
        _amount0 = _amount1 * reserve0 / (_amount1 + reserve1);
        reserve0 -= _amount0;
        reserve1 += _amount1;
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
    //投入流動性
    function addLiquidity (uint _amount0, uint _amount1) external returns (uint shares){
        if(reserve0 > 0 || reserve1 >0){
            require(_amount1 * reserve0 == _amount0 *reserve1,"Investment is not proportional");
        }
        if(totalSupply == 0){
            shares = _sqrt(_amount0 * _amount1);
        }else{
            shares = (_amount0 * totalSupply)/reserve0;
        }
        reserve0 += _amount0;
        reserve1 += _amount1; 
        totalSupply += shares;
        userBalance[msg.sender] += shares;
        return shares;
    }
    //減少流動性
    function minusLiquidity (uint _amountLp) external returns (uint _amount0,uint _amount1){
        require(userBalance[msg.sender] >= _amountLp,"Not enough LpToken");
        userBalance[msg.sender] -= _amountLp;
        _amount0 = (_amountLp * reserve0) / totalSupply;
        _amount1 = (_amountLp * reserve1) / totalSupply;
        totalSupply -= _amountLp;
        reserve0 -= _amount0;
        reserve1 -= _amount1;
    }
}