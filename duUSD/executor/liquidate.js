const { ethers } = require("ethers");
require('dotenv').config();

// RPC提供者和钱包设置
const provider = new ethers.providers.JsonRpcProvider("https://rpc-sepolia.rockx.com");
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// 合约地址和ABI
const priceOracleAddress = "0x6D1469289d76179B51E4EE77f7AE049AA8DcF598";
const priceOracleABI = [
    "function getPrice(address _token) external view returns (uint256)"
];
const controllerAddress = "0x3A0c546a46DCb78E790c80D047036fc6276eE2D4";
const controllerABI = [
    "function positions(address) public view returns (uint256 collateral, uint256 debt, uint256 liquidation_price)",
    "function liquidate(address user, bool use_eth) external"
];
const ammAddress = "0xA450D231F6a5eee28b2cD8b9840FBFA62F8b74A1"; // AMM合约地址
const ammABI = [
    "function share(address) public view returns (uint256)"
];

// 创建合约实例
const priceOracle = new ethers.Contract(priceOracleAddress, priceOracleABI, provider);
const controller = new ethers.Contract(controllerAddress, controllerABI, wallet);
const amm = new ethers.Contract(ammAddress, ammABI, provider);

async function checkAndLiquidate() {
    // const users = await controller.getAllUsers();
    const users = ["0xFCC7F5888bD3ed6De62f6fD82Dd8Ff8ee009Fc2b", "0xab9aa6caDE55b0ea543E234C5F86707ac7EA671B", "0x8061C28b479B846872132F593bC7cbC6b6C9D628"];

        for (const user of users) {
            const { collateral, debt, liquidation_price } = await controller.positions(user);
        const token = "0x6856Df502E66e966Fdd7019B31F3f0AdcBA92AfF"; 
        
        // 获取价格
        const price = await priceOracle.getPrice(token);
        console.log(`liquidation Price for ${user}: ${liquidation_price.toString()}`);
        // 比较价格并决定是否清算
        if (liquidation_price.gte(price)) {  // 使用BigNumber的比较方法
            const shareValue = await amm.share(user);
            if (shareValue.gt(0)) {
            console.log(`Liquidating ${user}...`);
            const tx = await controller.liquidate(user, false);  
            await tx.wait();
            console.log(`Liquidated ${user}`);
            }
        } else {
            console.log(`No liquidation needed for ${user}`);
        }
    }
}


setInterval(checkAndLiquidate, 30000); // 每60秒运行一次
