// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import "src/AMM.sol";
import "src/Controller.sol";
import "src/StableCoin.sol";
import "src/StablePool.sol";
import "src/stablizer/PegKeeper.sol";
import "src/interfaces/IPriceOracle.sol";
import "src/Mock/mockERC20.sol";
import "src/price_oracles/PriceOracle.sol";
import "src/Mock/mockERC20.sol";

import {Script, console} from "forge-std/Script.sol";

contract DeployScript is Script {
    address admin;
    address ReLayer;
    LLAMMA AMM_BTC;
    LLAMMA AMM_ETH;
    PriceOracle oracle;
    Controller controller_BTC;
    Controller controller_ETH;
    StableCoin stableCoin;
    StablePool stablePoolT;
    StablePool stablePoolC;
    PegKeeper pegKeeper;
    address ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address USDT = 0xcC808c2962bB8f2c92B269E04D536B702a8758A0;
    address USDC = 0xb6a230176F09D8638cA0832d52f16d35Fd055221;
    address BTC = 0x6856Df502E66e966Fdd7019B31F3f0AdcBA92AfF;

//    mockToken USDT = mockToken(payable(ContractsAddress.USDT));
    fallback() external payable {}
    receive() external payable {}

    function setUp() public {
        admin = 0xab9aa6caDE55b0ea543E234C5F86707ac7EA671B;
        ReLayer = 0xFCC7F5888bD3ed6De62f6fD82Dd8Ff8ee009Fc2b;
    }

    function run() external {
        vm.startBroadcast(0xab9aa6caDE55b0ea543E234C5F86707ac7EA671B);
        //set up stable coin
        stableCoin = new StableCoin(admin);
        //set up stable pool
        stablePoolT = new StablePool(address(stableCoin), address(USDT));
        stablePoolC = new StablePool(address(stableCoin), address(USDC));
        //set up oracle
        oracle = new PriceOracle(admin);
        oracle.setIsPriceFeed(admin, true);
        oracle.setPriceDecimals(address(BTC), 18);
        oracle.emitPriceEvent(address(BTC), 60000 * 10 ** 18);
        oracle.setPriceDecimals(ETHAddress, 18);
        oracle.emitPriceEvent(ETHAddress, 3000 * 10 ** 18);
        //set up AMM-BTC
        AMM_BTC = new LLAMMA(address(stableCoin), address(BTC), address(oracle));
        controller_BTC = new Controller( address(BTC), address(AMM_BTC), address(oracle), address(stableCoin));
        AMM_BTC.setAdmin(address(controller_BTC));
        stableCoin.mint(address(controller_BTC), 10000000 * (10 ** 18));
        //set up AMM-ETH
        AMM_ETH = new LLAMMA(address(stableCoin), ETHAddress, address(oracle));
        controller_ETH = new Controller( ETHAddress, address(AMM_ETH), address(oracle), address(stableCoin));
        AMM_ETH.setAdmin(address(controller_ETH));
        stableCoin.mint(address(controller_ETH), 10000000 * (10 ** 18));
        //set up PegKeeper
        pegKeeper = new PegKeeper(address(stableCoin));
        stableCoin.mint(address(pegKeeper), 100000 * (10 ** 18));
        //(BTC).mint(ReLayer, 10000 * (10 ** 18));
        //USDT.mint(ReLayer, 10000 * (10 ** 18));
        pegKeeper.addStablePool(address(stablePoolT), address(USDT));
        pegKeeper.addStablePool(address(stablePoolC), address(USDC));
        vm.stopBroadcast();
    }
}
