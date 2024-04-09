// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "src/interfaces/IPriceOracle.sol";
import "src/interfaces/ILLAMMA.sol";

// 事件声明
contract Controller {
    struct Position {
        uint256 collateral;
        uint256 debt;
        uint256 liquidation_price;
    }

    // 合约变量
    address public admin;
    ILLAMMA public immutable AMM;
    IERC20 public immutable STABLECOIN;
    IERC20 public immutable COLLATERAL_TOKEN;
    address public oracle;

    mapping(address => Position) public positions;
    // 构造函数
    constructor(address _collateralToken, address _amm, address _oracle, address _stablecoin) {
        admin = msg.sender;
        COLLATERAL_TOKEN = IERC20(_collateralToken);
        oracle = _oracle;
        AMM = ILLAMMA(_amm);
        STABLECOIN = IERC20(_stablecoin);
        STABLECOIN.approve(_amm, type(uint256).max);
    }

    function liquidate(address user, bool use_eth) external {
        require(msg.sender == admin, "Only admin can liquidate");
        Position memory position = positions[user];
        uint256 x = position.collateral;
        uint256 y = position.debt;
        uint256 liquidation_price = position.liquidation_price;
        uint256 price = IPriceOracle(oracle).getPrice(address(COLLATERAL_TOKEN));
        require(price < liquidation_price, "Price is above liquidation price");
        uint256 priceDecimal = IPriceOracle(oracle).getPriceDecimals(address(COLLATERAL_TOKEN));
        uint256 amount = y * price / (10 ** priceDecimal);
        if (use_eth) {
            AMM.removeLiquidityETH(address(STABLECOIN), x, user);
        } else {
            AMM.removeLiquidity(address(COLLATERAL_TOKEN),address(STABLECOIN), x, user);
        }
        STABLECOIN.transferFrom(user, address(this), y);
    }

    function depositETH() external payable {
        uint256 debt = msg.value * 6 / 10;
        uint256 price = IPriceOracle(oracle).getPrice(address(COLLATERAL_TOKEN));
        uint256 priceDecimal = IPriceOracle(oracle).getPriceDecimals(address(COLLATERAL_TOKEN));
        uint256 _amountToken = price / (10 ** priceDecimal) * msg.value;
        uint256 liquidation_price = price * 7 / 10;
        address account = msg.sender;
        STABLECOIN.transfer(account, debt);
        AMM.addLiquidityETH{value: msg.value}(address(STABLECOIN), _amountToken, msg.value, account);
        positions[msg.sender] = Position(msg.value, debt, liquidation_price);
    }

    function withdrawETH() external payable{
        require(positions[msg.sender].debt != 0 );
        uint256 price = IPriceOracle(oracle).getPrice(address(COLLATERAL_TOKEN));
        require(price >= positions[msg.sender].liquidation_price, "Position is at risk of liquidation");
        AMM.removeLiquidityETH(address(STABLECOIN), AMM.share(msg.sender), msg.sender);
        STABLECOIN.transferFrom(msg.sender, address(this), positions[msg.sender].debt);
        delete positions[msg.sender];
    }

    function deposit(uint amountIn) external {
        uint256 debt = amountIn * 6 / 10;
        uint256 price = IPriceOracle(oracle).getPrice(address(COLLATERAL_TOKEN));
        uint256 priceDecimal = IPriceOracle(oracle).getPriceDecimals(address(COLLATERAL_TOKEN));
        uint256 _amountToken = price / (10 ** priceDecimal) * amountIn;
        uint256 liquidation_price = price * 7 / 10;
        address account = msg.sender;
        STABLECOIN.transfer(account, debt);
        AMM.addLiquidity(amountIn, _amountToken, account);
        positions[msg.sender] = Position(amountIn, debt, liquidation_price);
    }

    function withdraw() external{
        uint256 price = IPriceOracle(oracle).getPrice(address(COLLATERAL_TOKEN));
        require(price >= positions[msg.sender].liquidation_price, "Position is at risk of liquidation");
        AMM.removeLiquidity(address(COLLATERAL_TOKEN), address(STABLECOIN), AMM.share(msg.sender), msg.sender);
        STABLECOIN.transferFrom(msg.sender, address(this), positions[msg.sender].debt);
        delete positions[msg.sender];
    }
}
