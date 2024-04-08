// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILLAMMA {
    function addLiquidityETH(address _token, uint _amountToken, uint _amountEth, address account) external payable;
    function removeLiquidityETH(address _token, uint _share, address account) external payable;
    function swapCForB(uint256 amountIn) external payable;
    function swapBForC(uint256 amountIn) external;
    function addLiquidity(uint _amountTokenA, uint _amountTokenB, address account) external;
    function removeLiquidity(address _tokenA, address _tokenB, uint256 _share, address account) external;
    function getAMAPrice() external view returns (uint256);
    function share(address account) external view returns (uint256);
}
