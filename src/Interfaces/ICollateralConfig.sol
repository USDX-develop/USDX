// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import {IGlobalConfig} from "./IGlobalConfig.sol";

interface ICollateralConfig {
    // --- Structs ---

    struct Config {
        bool isFrozen; // Freeze new operations (open, adjust up)
        bool isPaused; // Pause all operations except close
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
        bool isFrozen,
        bool isPaused,
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

    event Frozen(bool frozen);
    event Paused(bool paused);
    event AnnualInterestRateUpdated(uint256 newRate);
    event TreasuryUpdated(address newTreasury);
    event BorrowRatioUpdated(uint256 newRatio);
    event MintInterestFailed(uint256 oldRate, uint256 newRate);
    event MCRUpdated(uint256 newMCR);
    event CCRUpdated(uint256 newCCR);
    event SCRUpdated(uint256 newSCR);
    event LCRUpdated(uint256 newLCR);
    event MinDebtUpdated(uint256 newMinDebt);
    event LiquidationPenaltyLiquidatorUpdated(uint256 newPenalty);
    event LiquidationPenaltySpUpdated(uint256 newPenalty);
    event LiquidationPenaltyDaoUpdated(uint256 newPenalty);
    event LiquidationPenaltyDaoRecipientUpdated(address newRecipient);
    event GasCompensationUpdated(uint256 newGasCompensation);

    // --- Errors ---

    error InvalidAddress();
    error InvalidInterestRate();
    error InvalidBorrowRatio();
    error CollateralPaused();
    error CollateralFrozen();
    error TroveNotActive();

    // --- Setter Functions ---

    /**
     * @notice Set complete config
     */
    function setConfig(
        bool _isFrozen,
        bool _isPaused,
        uint256 _annualInterestRate,
        address _treasury,
        uint256 _borrowRatio,
        uint256 _MCR,
        uint256 _CCR,
        uint256 _SCR,
        uint256 _LCR,
        uint256 _minDebt,
        uint256 _liquidationPenaltyLiquidator,
        uint256 _liquidationPenaltySp,
        uint256 _liquidationPenaltyDao,
        address _liquidationPenaltyDaoRecipient,
        uint256 _gasCompensation
    ) external;

    function setGlobalConfig(address _globalConfig) external;

    function setAnnualInterestRate(uint256 _rate) external;

    // --- Getter Functions ---

    function getConfig() external view returns (Config memory);

    function isFrozen() external view returns (bool);

    function isPaused() external view returns (bool);

    function getAnnualInterestRate() external view returns (uint256);

    function getTreasury() external view returns (address);

    function getBorrowRatio() external view returns (uint256);

    function getMCR() external view returns (uint256);

    function getCCR() external view returns (uint256);

    function getSCR() external view returns (uint256);

    function getLCR() external view returns (uint256);

    function getMinDebt() external view returns (uint256);

    function getLiquidationPenaltyLiquidator() external view returns (uint256);

    function getLiquidationPenaltySp() external view returns (uint256);

    function getLiquidationPenaltyDao() external view returns (uint256);

    function getLiquidationPenaltyDaoRecipient() external view returns (address);

    function getGasCompensation() external view returns (uint256);

    // --- Check Functions ---

    /**
     * @notice Check if operations are allowed
     * @param _isIncrease True for operations that increase exposure (open, add collateral/debt)
     * @param _isDecrease True for operations that decrease exposure (close, withdraw collateral/debt)
     */
    function requireNotPausedOrFrozen(bool _isIncrease, bool _isDecrease) external view;
}
