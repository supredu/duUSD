// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "src/interfaces/IPriceOracle.sol";
import "src/interfaces/ILLAMMA.sol";


contract LLAMMA is ILLAMMA, Ownable, ReentrancyGuard{
    // State variables
    IERC20 public immutable borrowedToken; //duUSD
    IERC20 public immutable collateralToken;
    uint256 public borrowedTokenAmount;
    uint256 public collateralTokenAmount;
    IPriceOracle public immutable priceOracleContract;
    address public admin;
    uint256 public fee;
    uint256 public adminFee;
    uint256 public k;
    mapping (address => uint256) public share;

    // Events
    event TokenExchange(address indexed buyer, uint256 soldId, uint256 tokensSold, uint256 boughtId, uint256 tokensBought);
    event SetFee(uint256 fee);
    event SetAdminFee(uint256 fee);

    // Constructor
    constructor(address _borrowedToken, address _collateralToken, address _priceOracle) Ownable(msg.sender) {
        borrowedToken = IERC20(_borrowedToken);
        collateralToken = IERC20(_collateralToken);
        priceOracleContract = IPriceOracle(_priceOracle);
        admin = msg.sender;
        k = 1e18; // Initialization
    }

    // Function signatures
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "Only admin");
        admin = _admin;
        super.transferOwnership(_admin);
    }


    function setFee(uint256 _fee) external {
        require(msg.sender == admin, "Only admin");
        fee = _fee;
        emit SetFee(_fee);
    }

    function setAdminFee(uint256 _adminFee) external {
        require(msg.sender == admin, "Only admin");
        adminFee = _adminFee;
        emit SetAdminFee(_adminFee);
    }
    function addLiquidityETH(address _token, uint _amountToken, uint _amountEth,address account) external onlyOwner payable {
        require(msg.value == _amountEth, "ETH amount does not match with the value sent");
        uint256 collateralTokenAmountBefore = collateralTokenAmount;   
        collateralTokenAmount += msg.value;    
        IERC20 token = IERC20(_token);
        require(token.transferFrom(admin, address(this), _amountToken), "Token transfer failed");
        borrowedTokenAmount += _amountToken;
        uint256 liquidityTokensToMint = _amountEth;
        share[account] += liquidityTokensToMint;
        if (k == 1e18){
            k = collateralTokenAmount * borrowedTokenAmount;
        } else {
            k = (collateralTokenAmount / collateralTokenAmountBefore) * (collateralTokenAmount / collateralTokenAmountBefore) * k;
        }
    }
    function removeLiquidityETH(address _token, uint _share, address account) external onlyOwner payable {
        require(_share > 0, "Invalid share amount");
        require(share[account] >= _share, "Insufficient share");

        IERC20 token = IERC20(_token);
        uint256 amountEth = _share;
        uint256 amountToken = (borrowedTokenAmount * _share) / share[account];
        borrowedTokenAmount -= amountToken;
        uint256 collaterTokenAmountBefore = collateralTokenAmount;
        collateralTokenAmount -= amountEth;
        share[account] -= _share;
        payable(account).transfer(amountEth);
        require(token.transfer(admin, amountToken), "Token transfer failed");
        k = (collateralTokenAmount / collaterTokenAmountBefore) * (collateralTokenAmount / collaterTokenAmountBefore) * k;
    }

    function swapCForB(uint256 amountIn) external payable nonReentrant {
        uint256 amountOut;
        if (msg.value != 0){
            collateralTokenAmount += msg.value;
            amountOut = borrowedTokenAmount - k / collateralTokenAmount;
            borrowedTokenAmount -= amountOut;
            IERC20(borrowedToken).transfer(msg.sender, amountOut);
        }
        else {
            collateralTokenAmount += amountIn;
            amountOut = borrowedTokenAmount - k / collateralTokenAmount;
            borrowedTokenAmount -= amountOut;
            IERC20(borrowedToken).transfer(msg.sender, amountOut);
        }
    }
    function swapBForC(uint256 amountIn) external  nonReentrant {
        borrowedTokenAmount += amountIn;
        uint256 amountOut = collateralTokenAmount - k / borrowedTokenAmount;        
        borrowedTokenAmount -= amountOut;
        IERC20(collateralToken).transfer(msg.sender, amountOut);
    }

    function addLiquidity(uint _amountTokenA, uint _amountTokenB, address account) external onlyOwner {
        IERC20 tokenA = IERC20(collateralToken);
        IERC20 tokenB = IERC20(borrowedToken);
        uint256 collateralTokenAmountBefore = collateralTokenAmount;  
        require(tokenA.transferFrom(account, address(this), _amountTokenA), "collateralToken transfer failed");
        collateralTokenAmount += _amountTokenA; 

        require(tokenB.transferFrom(admin, address(this), _amountTokenB), "borrowedToken transfer failed");
        borrowedTokenAmount += _amountTokenB; //duUSD
        uint256 liquidityTokensToMint = _amountTokenA;
        share[account] += liquidityTokensToMint;
        if (k == 1e18){
            k = collateralTokenAmount * borrowedTokenAmount;
        } else {
            k = (collateralTokenAmount / collateralTokenAmountBefore) * (collateralTokenAmount / collateralTokenAmountBefore) * k;
        }
    }
    function removeLiquidity(address _tokenA, address _tokenB, uint256 _share, address account) external onlyOwner {
    require(share[account] >= _share, "Not enough liquidity tokens");

    uint256 amountTokenAReturn = _share ;
    uint256 amountTokenBReturn = (borrowedTokenAmount * _share) / share[account];

    require(collateralTokenAmount >= amountTokenAReturn, "Insufficient Token A in pool");
    require(borrowedTokenAmount >= amountTokenBReturn, "Insufficient Token B in pool");

    // Update the pool's token balances
    uint256 collateralTokenAmountBefore = collateralTokenAmount;
    collateralTokenAmount -= amountTokenAReturn;
    borrowedTokenAmount -= amountTokenBReturn;
    share[account] -= _share;

    // Transfer Token A and Token B back to the user
    IERC20(_tokenA).transfer(account, amountTokenAReturn);
    IERC20(_tokenB).transfer(admin, amountTokenBReturn);
    k = (collateralTokenAmount / collateralTokenAmountBefore) * (collateralTokenAmount / collateralTokenAmountBefore) * k;
}
    function getAMAPrice() external view returns (uint256) {
        return collateralTokenAmount / borrowedTokenAmount;
    }

    receive() external payable {}
}
