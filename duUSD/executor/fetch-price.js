const axios = require('axios');
const { ethers } = require("ethers");
require('dotenv').config();


const provider = new ethers.providers.JsonRpcProvider("https://rpc-sepolia.rockx.com");
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const priceOracleAddress = "0x6D1469289d76179B51E4EE77f7AE049AA8DcF598";
const priceOracleABI = [
    "function emitPriceEvent(address _token, uint256 _price) external"
];
const priceOracle = new ethers.Contract(priceOracleAddress, priceOracleABI, wallet);

async function fetchBTCPrices() {
  const urls = [
    'https://api1.binance.com/api/v3/trades?limit=1&symbol=BTCUSDT',
    'https://www.okx.com/api/v5/market/trades?limit=1&instId=BTC-USDT',
    'https://api.exchange.coinbase.com/products/BTC-USD/trades?limit=1'
  ];

  try {
    // 发起所有请求
    const responses = await Promise.all(urls.map(url => axios.get(url)));

    // 从响应中提取价格
    const prices = responses.map((response, index) => {
      if (index === 0) { // Binance
        return parseFloat(response.data[0].price);
      } else if (index === 1) { // OKX
        return parseFloat(response.data.data[0].px);
      } else if (index === 2) { // Coinbase
        return parseFloat(response.data[0].price);
      }
    });

    // 计算价格平均值
    const averagePrice = prices.reduce((acc, price) => acc + price, 0) / prices.length;

    // 打印平均价格
    console.log(`Average BTC Price: ${averagePrice.toFixed(2)}`);
    await priceOracle.emitPriceEvent(0x6856Df502E66e966Fdd7019B31F3f0AdcBA92AfF, ethers.utils.parseUnits(averagePrice.toFixed(2), 'ether'));
  } catch (error) {
    console.error('Error fetching BTC prices:', error);
  }
}

fetchBTCPrices();
