// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import {stdError} from "../../lib/forge-std/src/StdError.sol";

interface IGlobalConfig {
    // --- Structs ---

    struct Config {
        bool mintParsed; // Freeze new operations (open, adjust up)
        bool redeemParsed; // Freeze new operations (close, adjust down)
        bool globalPaused; // Pause all operations except close
        uint256 annualInterestRate; // Annual collateral interest rate (18 decimals)
        address treasury; // Treasury address for protocol revenue
        uint256 borrowRatio; // Borrow fee ratio (18 decimals, e.g., 5e15 = 0.5%)

        uint256 MCR; // Minimum collateral ratio for individual troves
        uint256 CCR; // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, some borrowing operation restrictions are applied
        uint256 SCR; // Shutdown system collateral ratio. If the system's total collateral ratio (TCR) for a given collateral falls below the SCR, the protocol triggers the shutdown of the borrow market and permanently disables all borrowing operations except for closing Troves.
        uint256 LCR; // Liquidation system collateral ratio. If the system's total collateral ratio (TCR) for a given collateral falls below the LCR, the protocol triggers liquidations.
        uint256 minDebt; // Minimum amount of net USDX debt a trove must have
        uint256 liquidationPenaltyLiquidator; // Liquidation penalty for troves liquidator
        uint256 liquidationPenaltySp; // Liquidation penalty for troves offset to the SP
        uint256 liquidationPenaltyDao; // Liquidation penalty for troves dao
        address liquidationPenaltyDaoRecipient; // Address of Liquidation dao penalty recipient address

        uint256 gasCompensation; // Amount of wxoc to be paid as gas compensation to liquidators
    }

    // --- Events ---

    event ConfigUpdated(
        bool mintParsed,
        bool redeemParsed,
        bool globalPaused,
        uint256 annualInterestRate,
        address treasury,
        uint256 borrowRatio,
        uint256 MCR,
        uint256 CCR,
        uint256 SCR,
        uint256 LCR,
        uint256 minDebt,
        uint256 liquidationPenaltyLiquidator,
        uint256 liquidationPenaltySp,
        uint256 liquidationPenaltyDao,
        address liquidationPenaltyDaoRecipient,
        uint256 gasCompensation
    );

    // --- Errors ---
    error InvalidAddress();
    error InvalidInterestRate();
    error InvalidBorrowRatio();
    error InvalidMCR();
    error InvalidCCR();
    error InvalidSCR();
    error InvalidLCR();

    // --- Setter Functions ---

    function setConfig(Config memory _config) external;

    // --- Getter Functions ---

    function getConfig() external view returns (Config memory);
}
