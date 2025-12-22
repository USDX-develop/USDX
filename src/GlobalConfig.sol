// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Interfaces/IGlobalConfig.sol";

/**
 * @title GlobalConfig
 * @notice Manages configuration parameters for global
 * @dev Each collateral has the same instance of this contract
 */
contract GlobalConfig is Initializable, OwnableUpgradeable, UUPSUpgradeable, IGlobalConfig
{
    // --- State Variables ---

    Config private config;

    // Constants
    uint256 private constant DECIMAL_PRECISION = 1e18;
    uint256 private constant MAX_COLL_ANNUAL_INTEREST_RATE = 1e18; // 100%
    uint256 private constant MAX_BORROW_RATIO = 1e17; // 10% max borrow fee

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the CollateralConfig contract
     * @param _initialOwner Owner address (typically governance or multisig)
     * @param _config Configuration parameters
     */
    function initialize(
        address _initialOwner,
        Config memory _config
    ) public initializer {
        __Ownable_init();
        transferOwnership(_initialOwner);

        setConfig(_config);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // --- Setter Functions (Owner only) ---

    /**
     * @notice Set complete config
     */
    function setConfig(
        Config memory _config
    ) public override onlyOwner {
        _requireValidAddress(_config.treasury);
        _requireValidInterestRate(_config.annualInterestRate);
        _requireValidBorrowRatio(_config.borrowRatio);
        _requireValidAddress(_config.liquidationPenaltyDaoRecipient);

        config = _config;

        emit ConfigUpdated(
            config.mintParsed,
            config.redeemParsed,
            config.globalPaused,
            config.annualInterestRate,
            config.treasury,
            config.borrowRatio,
            config.MCR,
            config.CCR,
            config.SCR,
            config.LCR,
            config.minDebt,
            config.liquidationPenaltyLiquidator,
            config.liquidationPenaltySp,
            config.liquidationPenaltyDao,
            config.liquidationPenaltyDaoRecipient,
            config.gasCompensation
        );
    }

    // --- Getter Functions (View) ---

    function getConfig() external view override returns (Config memory) {
        return config;
    }

    // --- Internal Functions ---

    function _requireValidAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
    }

    function _requireValidInterestRate(uint256 _rate) internal pure {
        // Max 100% annual rate (1e18 = 100%)
        if (_rate > MAX_COLL_ANNUAL_INTEREST_RATE) {
            revert InvalidInterestRate();
        }
    }

    function _requireValidBorrowRatio(uint256 _ratio) internal pure {
        // Max 10% borrow fee (1e17 = 10%)
        if (_ratio > MAX_BORROW_RATIO) {
            revert InvalidBorrowRatio();
        }
    }

    function _reqiredValidMCR(uint256 _MCR) internal pure {
        if (_MCR <= DECIMAL_PRECISION) {
            revert InvalidMCR();
        }
    }

    function _reqiredValidCCR(uint256 _CCR) internal pure {
        if (_CCR <= DECIMAL_PRECISION) {
            revert InvalidCCR();
        }
    }

    function _reqiredValidSCR(uint256 _SCR) internal pure {
        if (_SCR <= DECIMAL_PRECISION) {
            revert InvalidSCR();
        }
    }

    function _reqiredValidLCR(uint256 _LCR) internal pure {
        if (_LCR <= DECIMAL_PRECISION) {
            revert InvalidLCR();
        }
    }
}
