// FILE: src/controller.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";

// --- Interfaces for Token Contracts ---
interface INAU is IERC20 {
    function controllerBurn(address account, uint256 amount) external;
}

interface INAUXMintable is IERC20 {
    function controllerMint(address to, uint256 amount) external;
}

contract Controller is AccessControl {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    INAU public nau;
    INAUXMintable public nauy;
    INAUXMintable public naun;
    address public immutable reserveWallet;
    mapping(address => IUniswapV3Pool) public tokenToPool;
    uint32 public twapInterval;
    uint256 public constant FEE_BASIS_POINTS = 100; // 1% fee
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    address public quoteTokenAddress;
    uint256 public maxDataStalePeriodSeconds;
    AggregatorV3Interface public l2SequencerOracle;

    // --- Events ---
    event Transformed(address indexed user, uint256 amountNAU, uint256 amountNAUY, uint256 amountNAUN);
    event PoolUpdated(address indexed token, address indexed pool);
    event TokenAddressSet(bytes32 indexed tokenName, address indexed tokenAddress);
    event QuoteTokenUpdated(address indexed newQuoteToken);
    event TwapIntervalUpdated(uint32 newInterval);
    event MaxDataStalePeriodUpdated(uint256 newPeriod);
    event L2SequencerOracleUpdated(address indexed newOracle);

    // --- Constructor ---
    constructor(address reserveWalletAddress) {
        require(reserveWalletAddress != address(0), "Controller: Zero reserve wallet");
        reserveWallet = reserveWalletAddress;
        twapInterval = 60; // Set default TWAP interval
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        maxDataStalePeriodSeconds = 3600; // Default stale period: 1 hour
    }

    // --- Admin Functions ---
    function setTokenAddresses(address nauAddress, address nauyAddress, address naunAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(nauAddress != address(0), "Controller: Invalid NAU address");
        require(nauyAddress != address(0), "Controller: Invalid NAUY address");
        require(naunAddress != address(0), "Controller: Invalid NAUN address");
        nau = INAU(nauAddress);
        nauy = INAUXMintable(nauyAddress);
        naun = INAUXMintable(naunAddress);
        emit TokenAddressSet("NAU", nauAddress);
        emit TokenAddressSet("NAUY", nauyAddress);
        emit TokenAddressSet("NAUN", naunAddress);
    }

    function setQuoteToken(address quoteTokenAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(quoteTokenAddr != address(0), "Controller: Invalid quote token address");
        quoteTokenAddress = quoteTokenAddr;
        emit QuoteTokenUpdated(quoteTokenAddr);
    }

    function setPool(address token, address pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(token != address(0) && pool != address(0), "Controller: Invalid address");
        tokenToPool[token] = IUniswapV3Pool(pool);
        emit PoolUpdated(token, pool);
    }

    function setTwapInterval(uint32 newInterval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newInterval > 0, "Controller: TWAP interval must be greater than zero");
        twapInterval = newInterval;
        emit TwapIntervalUpdated(newInterval);
    }

    function setMaxDataStalePeriod(uint256 newPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newPeriod > 0, "Controller: Stale period must be greater than zero");
        maxDataStalePeriodSeconds = newPeriod;
        emit MaxDataStalePeriodUpdated(newPeriod);
    }

    function setL2SequencerOracle(address newOracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOracleAddress != address(0), "Controller: Oracle address cannot be zero");
        l2SequencerOracle = AggregatorV3Interface(newOracleAddress);
        emit L2SequencerOracleUpdated(newOracleAddress);
    }

    // --- Price Oracle Function ---
    function getTwapPrice(address tokenKey) public view returns (uint256 priceWad) {
        // L2 Sequencer Uptime Check
        if (address(l2SequencerOracle) != address(0)) {
            (, int256 price,, uint256 updatedAt,) = l2SequencerOracle.latestRoundData();
            require(price > 0, "Controller: L2 Sequencer is down");
            require(
                block.timestamp - updatedAt < maxDataStalePeriodSeconds, "Controller: L2 Sequencer heartbeat is stale"
            );
        }

        IUniswapV3Pool pool = tokenToPool[tokenKey];
        require(address(pool) != address(0), "Controller: No pool set for token key");
        require(quoteTokenAddress != address(0), "Controller: Quote token not set");

        (,, uint16 observationIndex, uint16 observationCardinality,,,) = pool.slot0();

        require(observationCardinality > 0, "Controller: Pool has no observations");
        uint256 lastObservationIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (uint32 blockTimestamp,,,) = pool.observations(lastObservationIndex);
        require(block.timestamp - blockTimestamp <= maxDataStalePeriodSeconds, "Controller: Price data is stale");

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;
        (int56[] memory tickCumulatives,) = pool.observe(secondsAgos);
        int56 tickDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 meanTick;
        require(twapInterval > 0, "Controller: TWAP interval cannot be zero");
        int56 twapIntervalInt56 = int56(int32(twapInterval));
        meanTick = int24(tickDelta / twapIntervalInt56);
        if (tickDelta < 0 && (tickDelta % twapIntervalInt56 != 0)) {
            meanTick--;
        }
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(meanTick);

        address token0 = pool.token0();
        address token1 = pool.token1();
        uint8 decimals0 = IERC20Metadata(token0).decimals();
        uint8 decimals1 = IERC20Metadata(token1).decimals();

        uint256 priceNumerator = uint256(sqrtPriceX96) * uint256(sqrtPriceX96);
        uint256 priceDenominator = uint256(FixedPoint96.Q96) * uint256(FixedPoint96.Q96);

        uint256 baseRatio_18 = 0;
        int256 adjustment_exponent = 0;

        if (token0 == quoteTokenAddress) {
            require(token1 != quoteTokenAddress, "Controller: Pool cannot be Quote/Quote");
            baseRatio_18 = FullMath.mulDiv(priceDenominator, 1e18, priceNumerator);
            adjustment_exponent = int256(uint256(decimals1)) - int256(uint256(decimals0));
        } else if (token1 == quoteTokenAddress) {
            require(token0 != quoteTokenAddress, "Controller: Pool cannot be Quote/Quote");
            baseRatio_18 = FullMath.mulDiv(priceNumerator, 1e18, priceDenominator);
            adjustment_exponent = int256(uint256(decimals0)) - int256(uint256(decimals1));
        } else {
            revert("Controller: Pool does not contain quote token");
        }

        if (adjustment_exponent == 0) {
            priceWad = baseRatio_18;
        } else if (adjustment_exponent > 0) {
            require(adjustment_exponent < 78, "Adjustment exponent too large");
            uint256 factor = 10 ** uint256(adjustment_exponent);
            priceWad = FullMath.mulDiv(baseRatio_18, factor, 1);
        } else {
            uint256 positive_adjustment_exponent = uint256(-adjustment_exponent);
            require(positive_adjustment_exponent < 78, "Adjustment exponent too small");
            uint256 divisor = 10 ** positive_adjustment_exponent;
            priceWad = FullMath.mulDiv(baseRatio_18, 1, divisor);
        }
    }

    // --- Core Transformation Function ---
    function transformX(uint256 amountNAU, uint256 ratioX1, uint256 ratioX2) external {
        require(amountNAU > 0, "Controller: Amount must be > 0");
        require(ratioX1 + ratioX2 == 10000, "Controller: Ratios must total 10000");

        uint256 feeAmount = FullMath.mulDiv(amountNAU, FEE_BASIS_POINTS, BASIS_POINTS_DIVISOR);
        uint256 netAmount = amountNAU - feeAmount;

        IERC20(address(nau)).safeTransferFrom(msg.sender, address(this), amountNAU);
        IERC20(address(nau)).safeTransfer(reserveWallet, feeAmount);

        nau.controllerBurn(address(this), netAmount);

        uint256 priceNAU = getTwapPrice(address(nau));
        uint256 priceNAUY = getTwapPrice(address(nauy));
        uint256 priceNAUN = getTwapPrice(address(naun));

        uint256 totalValueInQuote = FullMath.mulDiv(netAmount, priceNAU, 1e18);

        uint256 valueNAUYInQuote = FullMath.mulDiv(totalValueInQuote, ratioX1, 10000);
        uint256 valueNAUNInQuote = totalValueInQuote - valueNAUYInQuote;

        require(priceNAUY > 0, "Controller: NAUY price is zero");
        require(priceNAUN > 0, "Controller: NAUN price is zero");
        uint256 amountNAUY = FullMath.mulDiv(valueNAUYInQuote, 1e18, priceNAUY);
        uint256 amountNAUN = FullMath.mulDiv(valueNAUNInQuote, 1e18, priceNAUN);

        nauy.controllerMint(msg.sender, amountNAUY);
        naun.controllerMint(msg.sender, amountNAUN);

        emit Transformed(msg.sender, amountNAU, amountNAUY, amountNAUN);
    }

    // --- Admin Renunciation ---
    function renounceAdmin() external {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
