// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "src/interfaces/IPriceOracle.sol";
pragma solidity ^0.8.0;

contract PriceOracle is IPriceOracle, Ownable {

    mapping (address => bool) public isPriceFeed;
    mapping (address => uint8) public priceDecimals;
    mapping (address => uint256) public price;
    event PriceUpdate(address token, uint256 price, address priceFeed);

    constructor(address initialOwner) Ownable(initialOwner) {
    }

    function setIsPriceFeed(address _priceFeed, bool _isPriceFeed) external onlyOwner {
      isPriceFeed[_priceFeed] = _isPriceFeed;
    }

    function emitPriceEvent(address _token, uint256 _price) external  {
      require(isPriceFeed[msg.sender], "PriceOracleEvents: invalid sender");
      price[_token] = _price;
      emit PriceUpdate(_token, _price, msg.sender);
    }

    function getPrice(address _token) external view returns (uint256) {
      return price[_token];
    }

    function setPriceDecimals(address _token, uint8 _priceDecimals) external onlyOwner {
      priceDecimals[_token] = _priceDecimals;
    }

    function getPriceDecimals(address _token) external view returns (uint8) {
      return priceDecimals[_token];
    }
}
