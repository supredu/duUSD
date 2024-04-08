// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPriceOracle {
    function getPrice(address _token) external view returns (uint256);
    function setPriceDecimals(address _token, uint8 _priceDecimals) external;
    function getPriceDecimals(address _token) external view returns (uint8);
    function emitPriceEvent(address _token, uint256 _price) external;
    function setIsPriceFeed(address _priceFeed, bool _isPriceFeed) external;
}