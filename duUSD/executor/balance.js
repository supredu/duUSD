const { ethers } = require("ethers");
require('dotenv').config();

const provider = new ethers.providers.JsonRpcProvider("https://rpc-sepolia.rockx.com");

// 定义合约地址和ABI
const duUSDAddress = "0x8BAadB36Ad72A0D226ad3bEec6514CBFF3252741";
const stablePoolAddress = "0x7b9b43A78c3F063F06e232420fbDaC04dd3e98e8";
const pegKeeperAddress = "0xA2b23244A414a1dDf2b295b63e9bA499a013e025";
const USDTAddress = "0xcC808c2962bB8f2c92B269E04D536B702a8758A0";

const privateKey = process.env.PRIVATE_KEY;
const wallet = new ethers.Wallet(privateKey, provider);

const erc20ABI = [
    "function balanceOf(address owner) view returns (uint256)",
    "function transfer(address to, uint amount) returns (bool)",
    "function transferFrom(address from, address to, uint amount) returns (bool)"
];

const pegKeeperABI = [
    "function balance(address stablePool, bool isMint, uint256 amount) external"
];

// 连接到合约实例
const duUSD = new ethers.Contract(duUSDAddress, erc20ABI, provider);
const token1 = new ethers.Contract(duUSDAddress, erc20ABI, provider);
const token2 = new ethers.Contract(USDTAddress, erc20ABI, provider);
const pegKeeper = new ethers.Contract(pegKeeperAddress, pegKeeperABI, wallet);

async function monitorAndReact() {
    const balance1 = await token1.balanceOf(stablePoolAddress);
    console.log('duUSD balacne', balance1.toString());
    const balance2 = await token2.balanceOf(stablePoolAddress);
    console.log('USDT balacne', balance2.toString());

    // 使用 BigNumber 来比较和计算
    const price = balance2.mul(ethers.BigNumber.from(1000)).div(balance1);
    console.log(`Current price: ${ethers.utils.formatUnits(price, 3)}`); // 转换为更易读的数字，精确到小数点后3位

    const onePointOne = ethers.BigNumber.from(1100); // 表示1.1*1000，以保持比较时的精度
    const zeroPointNine = ethers.BigNumber.from(900); // 表示0.9*1000

    if (price.gt(onePointOne)) {
        // 价格高于1.1
        const amount = balance2.sub(balance1);
        await pegKeeper.balance(stablePoolAddress, true, amount);
        console.log(`Executed mint with amount: ${amount.toString()}`);
    } else if (price.lt(zeroPointNine)) {
        // 价格低于0.9
        const amount = balance1.sub(balance2);
        await pegKeeper.balance(stablePoolAddress, false, amount);
        console.log(`Executed burn with amount: ${amount.toString()}`);
    }
}

// 定期检查价格并作出反应
setInterval(monitorAndReact, 30000); // 每30秒运行一次
