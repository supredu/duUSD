// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStablePool {
    /**
     * @dev 添加流动性到池子中。
     * @param token1Amount 第一个代币的数量。
     * @param token2Amount 第二个代币的数量。
     */
    function addLiquidity(uint256 token1Amount, uint256 token2Amount) external;

    /**
     * @dev 从池子中移除流动性。
     * @param liquidity 要移除的流动性数量。
     */
    function removeLiquidity(uint256 liquidity) external;

    /**
     * @dev 执行代币兑换。
     * @param fromToken 兑换使用的代币地址。
     * @param amountIn 兑换的代币数量。
     */
    function swap(address fromToken, uint256 amountIn) external;

    /**
     * @dev 计算给定输入金额的输出金额。
     * @param amountIn 输入的代币数量。
     * @param reserveIn 输入代币的储备量。
     * @param reserveOut 输出代币的储备量。
     * @return 输出的代币数量。
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256);

    /**
     * @dev 获取代币的价格。
     * @param isToken1 如果为true，则返回token1对token2的价格，反之则相反。
     * @return 代币的价格。
     */
    function getPrice(bool isToken1) external view returns (uint256);
}
