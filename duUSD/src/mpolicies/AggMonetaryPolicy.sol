// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPegKeeper {
    function debt() external view returns (uint256);
}

interface IPriceOracle {
    function price() external view returns (uint256);
}

interface IControllerFactory {
    function total_debt() external view returns (uint256);
}

contract AggMonetaryPolicy {
    address public admin;
    uint256 public rate0;
    int256 public sigma;
    uint256 public target_debt_fraction;

    IPegKeeper[1001] public peg_keepers;
    IPriceOracle public immutable PRICE_ORACLE;
    IControllerFactory public immutable CONTROLLER_FACTORY;

    uint256 public constant MAX_TARGET_DEBT_FRACTION = 10**18;
    uint256 public constant MAX_SIGMA = 10**18;
    uint256 public constant MIN_SIGMA = 10**14;
    uint256 public constant MAX_EXP = 1000 * 10**18;
    uint256 public constant MAX_RATE = 43959106799; // 300% APY

    event SetAdmin(address indexed admin);
    event AddPegKeeper(address indexed peg_keeper);
    event RemovePegKeeper(address indexed peg_keeper);
    event SetRate(uint256 rate);
    event SetSigma(uint256 sigma);
    event SetTargetDebtFraction(uint256 target_debt_fraction);

    constructor(
        address _admin,
        IPriceOracle _priceOracle,
        IControllerFactory _controllerFactory,
        IPegKeeper[5] memory _pegKeepers,
        uint256 _rate,
        uint256 _sigma,
        uint256 _targetDebtFraction
    ) {
        admin = _admin;
        PRICE_ORACLE = _priceOracle;
        CONTROLLER_FACTORY = _controllerFactory;
        for (uint i = 0; i < _pegKeepers.length; i++) {
            if (address(_pegKeepers[i]) == address(0)) {
                break;
            }
            peg_keepers[i] = _pegKeepers[i];
        }

        require(_sigma >= MIN_SIGMA, "Sigma is below minimum");
        require(_sigma <= MAX_SIGMA, "Sigma is above maximum");
        require(_targetDebtFraction <= MAX_TARGET_DEBT_FRACTION, "Target debt fraction is above maximum");
        require(_rate <= MAX_RATE, "Rate is above maximum");
        rate0 = _rate;
        sigma = int256(_sigma);
        target_debt_fraction = _targetDebtFraction;
    }

    // Set admin and other external functions similar to the Vyper version would go here

    // The exp and calculate_rate internal functions would need to be translated to Solidity,
    // considering the differences in mathematical operations and type safety between Vyper and Solidity.
    // Note: The precise translation of the exp function would depend on the specific mathematical requirements
    // and might require using a library for safe math operations or an existing implementation if available.

    // rate and rate_write functions, event emitters, and other logic from the Vyper contract
    // should be translated considering Solidity's syntax and features.
}
