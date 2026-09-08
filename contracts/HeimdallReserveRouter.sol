// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Heimdall Automated 17% Hard-Asset Treasury Reserve Router
 * @notice Receives 17% of Heimdall Node hardware sales ($76.50/unit) and automatically
 *         swaps into Physical Gold (PAXG) and Bitcoin (cbBTC) on Base L2, depositing
 *         directly into the RandRTech ($RNR) audited backing reserve vaults.
 * 
 * ALLOCATION BREAKDOWN ($450 RETAIL NODE):
 * - 17% Reserve Peg Allocation = $76.50 USD / USDC per unit.
 * - 50% of allocation ($38.25) -> Swapped to PAXG (Paxos Physical Gold).
 * - 50% of allocation ($38.25) -> Swapped to cbBTC (Coinbase Wrapped Bitcoin: 0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf).
 * - Deposited into RandRTech reserve vault addresses on Base.
 */

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract HeimdallReserveRouter {
    address public owner;
    address public immutable usdcToken;
    address public immutable paxgToken;   // Paxos Gold on Base
    address public immutable cbBtcToken;  // cbBTC on Base: 0xcbb7c0000ab88b473b1f5afd9ef808440eed33bf
    address public immutable swapRouter;  // Uniswap V3 SwapRouter on Base

    address public goldReserveVault;
    address public btcReserveVault;

    uint24 public constant POOL_FEE_TIER = 500; // 0.05% or 0.3%

    // Fixed 17% allocation formula per $450 node
    uint256 public constant NODE_RETAIL_PRICE_USDC = 450 * 10**6; // 6 decimals for USDC
    uint256 public constant PEG_ALLOCATION_BPS = 1700;           // 17.00%
    uint256 public constant PER_NODE_PEG_USDC = 76_500_000;       // $76.50 USDC

    event PegSweepExecuted(
        uint256 totalUsdcAllocated,
        uint256 goldUsdcSpent,
        uint256 paxgReceived,
        uint256 btcUsdcSpent,
        uint256 cbBtcReceived,
        uint256 timestamp
    );

    event VaultAddressesUpdated(address indexed newGoldVault, address indexed newBtcVault);

    modifier onlyOwner() {
        require(msg.sender == owner, "HeimdallRouter: Caller is not owner");
        _;
    }

    constructor(
        address _usdcToken,
        address _paxgToken,
        address _cbBtcToken,
        address _swapRouter,
        address _goldVault,
        address _btcVault
    ) {
        owner = msg.sender;
        usdcToken = _usdcToken;
        paxgToken = _paxgToken;
        cbBtcToken = _cbBtcToken;
        swapRouter = _swapRouter;
        goldReserveVault = _goldVault;
        btcReserveVault = _btcVault;
    }

    /**
     * @notice Sweeps 17% hardware sales allocation into Gold and Bitcoin.
     * @param usdcAmount Total USDC available to route into backing reserves.
     * @param minPaxgOut Minimum acceptable PAXG output (slippage protection).
     * @param minCbBtcOut Minimum acceptable cbBTC output (slippage protection).
     */
    function routeHardwarePeg(
        uint256 usdcAmount,
        uint256 minPaxgOut,
        uint256 minCbBtcOut
    ) external onlyOwner {
        require(usdcAmount > 0, "No USDC specified");
        require(IERC20(usdcToken).transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");

        uint256 half = usdcAmount / 2;
        uint256 otherHalf = usdcAmount - half;

        // Approve router for swaps
        IERC20(usdcToken).approve(swapRouter, usdcAmount);

        // 1. Swap 50% USDC -> PAXG (Paxos Gold) directly to Gold Reserve Vault
        ISwapRouter.ExactInputSingleParams memory goldParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: usdcToken,
            tokenOut: paxgToken,
            fee: POOL_FEE_TIER,
            recipient: goldReserveVault,
            deadline: block.timestamp + 300,
            amountIn: half,
            amountOutMinimum: minPaxgOut,
            sqrtPriceLimitX96: 0
        });
        uint256 paxgReceived = ISwapRouter(swapRouter).exactInputSingle(goldParams);

        // 2. Swap 50% USDC -> cbBTC (Bitcoin) directly to BTC Reserve Vault
        ISwapRouter.ExactInputSingleParams memory btcParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: usdcToken,
            tokenOut: cbBtcToken,
            fee: POOL_FEE_TIER,
            recipient: btcReserveVault,
            deadline: block.timestamp + 300,
            amountIn: otherHalf,
            amountOutMinimum: minCbBtcOut,
            sqrtPriceLimitX96: 0
        });
        uint256 cbBtcReceived = ISwapRouter(swapRouter).exactInputSingle(btcParams);

        emit PegSweepExecuted(usdcAmount, half, paxgReceived, otherHalf, cbBtcReceived, block.timestamp);
    }

    function setVaults(address _goldVault, address _btcVault) external onlyOwner {
        require(_goldVault != address(0) && _btcVault != address(0), "Invalid vault address");
        goldReserveVault = _goldVault;
        btcReserveVault = _btcVault;
        emit VaultAddressesUpdated(_goldVault, _btcVault);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }
}
