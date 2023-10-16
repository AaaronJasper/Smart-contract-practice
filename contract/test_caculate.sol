// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC20_LPtoken.sol";

contract caculatetest{
    //計算手續費並增發LPtoken
    function caculateFee () public pure returns(uint) {
        uint reserve0 = 84948;
        uint reserve1 = 42380;
        uint k = 3600000000 * 1e8;
        uint newK = (reserve0 * reserve1) * 1e8;
        uint newKK = _sqrt(newK);
    
        // 检查参数范围
        //require(newK >= k, "Invalid parameters");
    
        // 直接計算
        uint ans = ((_sqrt(newK) - _sqrt(k)) * 60000) * 1e8/ ((5 * _sqrt(newK)) + _sqrt(k));
        // 使用整数进行计算
        //uint k2 = _sqrt(newK);
        //uint k1 = _sqrt(k);
        //uint smTop = (k1 - k2) * 60000; 
        //uint smUnder = ((5 * k2) + k1);
    
    
        // 计算结果
        //uint sm = (smTop) * 10000 / smUnder; // 乘以10^18保留足够的精度
    
        return ans;
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