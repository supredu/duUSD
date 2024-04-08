// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/IStablePool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PegKeeper is Ownable {
    address public duUSD;
    mapping (address => address) public PairToken; // stablepool => pairtoken
    address[] stablePools;
    constructor(address _duUSD) Ownable(msg.sender){
        duUSD = _duUSD;
    }
    function addStablePool(address _stablePool, address _pairToken) external onlyOwner {
        stablePools.push(_stablePool);
        PairToken[_stablePool] = _pairToken;
    }
    function balance(address stablePool, bool isMint, uint256 amount) external onlyOwner{
        if (isMint == true){
            IERC20(duUSD).transfer(stablePool,amount);
        }
        else{
            IERC20(duUSD).transferFrom(stablePool,address(this),amount);
        }
    }
}
