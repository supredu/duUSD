// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/IStablePool.sol";

contract StablePool is IStablePool{
    address public token1;
    address public token2;
    uint256 public reserve1;
    uint256 public reserve2;

    constructor(address _token1, address _token2) {
        token1 = _token1;
        token2 = _token2;
    }


    function addLiquidity(uint256 token1Amount, uint256 token2Amount) external {
        require(token1Amount > 0 && token2Amount > 0, "Invalid amounts");
        
        require(token1Amount == token2Amount, "Must maintain constant sum");

        IERC20(token1).transferFrom(msg.sender, address(this), token1Amount);
        IERC20(token2).transferFrom(msg.sender, address(this), token2Amount);
        reserve1 += token1Amount;
        reserve2 += token2Amount;
    }

    function removeLiquidity(uint256 liquidity) external {
        require(liquidity > 0, "Invalid liquidity amount");

        uint256 token1Amount = (liquidity * reserve1) / (reserve1 + reserve2);
        uint256 token2Amount = (liquidity * reserve2) / (reserve1 + reserve2);
        require(token1Amount > 0 && token2Amount > 0, "Invalid amounts");

        reserve1 -= token1Amount;
        reserve2 -= token2Amount;
        IERC20(token1).transfer(msg.sender, token1Amount);
        IERC20(token2).transfer(msg.sender, token2Amount);
    }

    function swap(address fromToken, uint256 amountIn) external {
        require(fromToken == token1 || fromToken == token2, "Invalid fromToken");
        require(amountIn > 0, "Invalid input amount");

        uint256 amountOut;
        if (fromToken == token1) {
            require(reserve1 + amountIn > reserve1, "Overflow");
    
            amountOut = reserve2 - (reserve1 + amountIn - reserve2);
            reserve1 += amountIn;
            reserve2 -= amountOut;
            IERC20(token1).transferFrom(msg.sender, address(this), amountIn);
            IERC20(token2).transfer(msg.sender, amountOut);
        } else {
            require(reserve2 + amountIn > reserve2, "Overflow");
            amountOut = reserve1 - (reserve2 + amountIn - reserve1);
            reserve2 += amountIn;
            reserve1 -= amountOut;
            IERC20(token2).transferFrom(msg.sender, address(this), amountIn);
            IERC20(token1).transfer(msg.sender, amountOut);
        }
    }


    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public view returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint256 amountOut = reserveOut - (reserveIn + amountIn - reserveOut);
        return amountOut;
    }

    function getPrice(bool isToken1) public view returns (uint256){
        if (isToken1 == true){
            return IERC20(token2).balanceOf(address(this))  / IERC20(token1).balanceOf(address(this));
        } else {
            return IERC20(token1).balanceOf(address(this)) / IERC20(token2).balanceOf(address(this));
        }
    }
}

