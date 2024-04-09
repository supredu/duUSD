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


contract duUSDTest is Test {

    address admin;
    address ReLayer;
    LLAMMA AMM;
    PriceOracle oracle;
    Controller controller;
    StableCoin stableCoin;
    StablePool stablePool;
    PegKeeper pegKeeper;
    address ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
//    mockWETH WETH = new mockWETH();
    mockToken USDT = new mockToken("USDT", "USDT");
    mockToken BTC = new mockToken("BTC", "BTC");
//    mockToken USDT = mockToken(payable(ContractsAddress.USDT));
    fallback() external payable {}
    receive() external payable {}

    function setUp() public {
        console.log("start"); 
        admin = makeAddr("admin");
        ReLayer = makeAddr("ReLayer");
        vm.deal(address(this), 10 ether);
        vm.deal(ReLayer, 1000 ether);
        vm.startPrank(admin);
        stableCoin = new StableCoin(admin);
        stablePool = new StablePool(address(stableCoin), address(USDT));
        oracle = new PriceOracle(admin);
        oracle.setIsPriceFeed(admin, true);
        oracle.setPriceDecimals(address(BTC), 18);
        oracle.emitPriceEvent(address(BTC), 60000 * 10 ** 18);
        console.log("oracle init success");
        AMM = new LLAMMA(address(stableCoin), address(BTC), address(oracle));
        controller = new Controller( address(BTC), address(AMM), address(oracle), address(stableCoin));
        AMM.setAdmin(address(controller));
        stableCoin.mint(address(controller), 10000000 * (10 ** 18));
        pegKeeper = new PegKeeper(address(stableCoin));
        console.log("initiliaze successful");
        stableCoin.mint(address(pegKeeper), 10000 * (10 ** 18));
        BTC.mint(ReLayer, 10000 * (10 ** 18));
        USDT.mint(ReLayer, 10000 * (10 ** 18));
        pegKeeper.addStablePool(address(stableCoin), address(USDT));
        console.log("pegKeeper init success");
        console.log(stableCoin.balanceOf(address(pegKeeper))); 
        pegKeeper.balance(address(stablePool), true, 100 * (10 ** 18));
        console.log("balanced");
        console.log(stableCoin.balanceOf(address(pegKeeper))); 
        console.log("setup success");
        vm.stopPrank();


    }

    function test_deposit() public {
        vm.startPrank(ReLayer);
        BTC.approve(address(AMM), 1000 * (10 ** 18));
        controller.deposit(100 * (10 ** 18));
        console.log(AMM.collateralTokenAmount());
        console.log(AMM.borrowedTokenAmount());
        console.log(AMM.share(ReLayer));
        console.log(AMM.k());
        vm.stopPrank();
    }

    function test_withdraw_after_deposit() public {
        vm.startPrank(ReLayer);
        stableCoin.approve(address(controller), 10000 * (10 ** 18));
        BTC.approve(address(AMM), 1000 * (10 ** 18));
        controller.deposit(100 * (10 ** 18));
        controller.withdraw();
        console.log(AMM.collateralTokenAmount());
        console.log(AMM.borrowedTokenAmount());
        console.log(AMM.share(ReLayer));
        console.log(AMM.k());
        vm.stopPrank();
    }
        
    function test_liquidate() public {
        vm.startPrank(ReLayer);
        stableCoin.approve(address(controller), 10000 * (10 ** 18));
        BTC.approve(address(AMM), 1000 * (10 ** 18));
        controller.deposit(100 * (10 ** 18));
        vm.stopPrank();
        vm.startPrank(admin);
        oracle.emitPriceEvent(address(BTC), 30000 * 10 ** 18);
        controller.liquidate(ReLayer, false);
        console.log(AMM.collateralTokenAmount());
        console.log(AMM.borrowedTokenAmount());
        console.log(AMM.share(ReLayer));
        console.log(AMM.k());
        vm.stopPrank();
    } 
        
    
}
