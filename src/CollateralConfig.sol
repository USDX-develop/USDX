// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Interfaces/ICollateralConfig.sol";
import "./Interfaces/IActivePool.sol";
import "./Interfaces/IGlobalConfig.sol";
import "./Interfaces/ITroveManager.sol";

/**
 * @title CollateralConfig
 * @notice Manages configuration parameters for a specific collateral type
 * @dev Each collateral has its own instance of this contract
 */
contract CollateralConfig is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ICollateralConfig
{
    // --- State Variables ---

    Config public config;
    IActivePool public activePool;
    IGlobalConfig public globalConfig;

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
     * @param _activePool ActivePool contract
     */
    function initialize(
        address _initialOwner,
        address _activePool,
        IGlobalConfig _globalConfig
    ) public initializer {
        __Ownable_init();
        transferOwnership(_initialOwner);

        _requireValidAddress(_globalConfig.getConfig().treasury);
        _requireValidAddress(_activePool);

        activePool = IActivePool(_activePool);

        config = Config({
            isFrozen: _globalConfig.getConfig().mintPaused,
            isPaused: _globalConfig.getConfig().globalPaused,
            annualInterestRate: _globalConfig.getConfig().annualInterestRate,
            treasury: _globalConfig.getConfig().treasury,
            borrowRatio: _globalConfig.getConfig().borrowRatio,
            MCR: _globalConfig.getConfig().MCR,
            CCR: _globalConfig.getConfig().CCR,
            SCR: _globalConfig.getConfig().SCR,
            LCR: _globalConfig.getConfig().LCR,
            minDebt: _globalConfig.getConfig().minDebt,
            liquidationPenaltyLiquidator: _globalConfig.getConfig().liquidationPenaltyLiquidator,
            liquidationPenaltySp: _globalConfig.getConfig().liquidationPenaltySp,
            liquidationPenaltyDao: _globalConfig.getConfig().liquidationPenaltyDao,
            liquidationPenaltyDaoRecipient: _globalConfig.getConfig().liquidationPenaltyDaoRecipient,
            gasCompensation: _globalConfig.getConfig().gasCompensation
        });

        globalConfig = _globalConfig;

        emit ConfigUpdated(
            config.isFrozen,
            config.isPaused,
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

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // --- Setter Functions (Owner only) ---

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
    ) external override onlyOwner {
        _requireValidAddress(_treasury);
        _requireValidInterestRate(_annualInterestRate);
        _requireValidBorrowRatio(_borrowRatio);

        config.isFrozen = _isFrozen;
        config.isPaused = _isPaused;
        config.annualInterestRate = _annualInterestRate;
        config.treasury = _treasury;
        config.borrowRatio = _borrowRatio;
        config.MCR = _MCR;
        config.CCR = _CCR;
        config.SCR = _SCR;
        config.LCR = _LCR;
        config.minDebt = _minDebt;
        config.liquidationPenaltyLiquidator = _liquidationPenaltyLiquidator;
        config.liquidationPenaltySp = _liquidationPenaltySp;
        config.liquidationPenaltyDao = _liquidationPenaltyDao;
        config.liquidationPenaltyDaoRecipient = _liquidationPenaltyDaoRecipient;
        config.gasCompensation = _gasCompensation;

        emit ConfigUpdated(
            _isFrozen,
            _isPaused,
            _annualInterestRate,
            _treasury,
            _borrowRatio,
            _MCR,
            _CCR,
            _SCR,
            _LCR,
            _minDebt,
            _liquidationPenaltyLiquidator,
            _liquidationPenaltySp,
            _liquidationPenaltyDao,
            _liquidationPenaltyDaoRecipient,
            _gasCompensation
        );
    }

    /**
     * @notice Freeze/unfreeze collateral (prevents new operations)
     */
    function setFrozen(bool _frozen) external override onlyOwner {
        config.isFrozen = _frozen;
        emit Frozen(_frozen);
    }

    /**
     * @notice Pause/unpause collateral (prevents all operations except close)
     */
    function setPaused(bool _paused) external override onlyOwner {
        config.isPaused = _paused;
        emit Paused(_paused);
    }

    function setGlobalConfig(address _globalConfig) external override onlyOwner {
        _requireValidAddress(_globalConfig);
        globalConfig = IGlobalConfig(_globalConfig);
    }

    /**
     * @notice Update collateral annual interest rate
     * @param _rate Annual interest rate in 18 decimals (e.g., 5e16 = 5%)
     * @dev Triggers mintAggInterest before updating rate to settle old rate's interest
     */
    function setAnnualInterestRate(
        uint256 _rate,
        address _troveManager
    ) external override onlyOwner {
        _requireValidInterestRate(_rate);

        uint256 oldRate = config.annualInterestRate;
        if (oldRate == _rate) return;

        ITroveManager troveManagerCached = ITroveManager(_troveManager);
        config.annualInterestRate = _rate;
        emit AnnualInterestRateUpdated(_rate);
    }

    /**
     * @notice Update treasury address
     */
    function setTreasury(address _treasury) external override onlyOwner {
        _requireValidAddress(_treasury);
        config.treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /**
     * @notice Update borrow fee ratio
     * @param _ratio Borrow fee ratio in 18 decimals (e.g., 5e15 = 0.5%)
     */
    function setBorrowRatio(uint256 _ratio) external override onlyOwner {
        _requireValidBorrowRatio(_ratio);
        config.borrowRatio = _ratio;
        emit BorrowRatioUpdated(_ratio);
    }

    function setMCR(uint256 _MCR) external override onlyOwner {
        config.MCR = _MCR;
        emit MCRUpdated(_MCR);
    }

    function setCCR(uint256 _CCR) external override onlyOwner {
        config.CCR = _CCR;
        emit CCRUpdated(_CCR);
    }

    function setSCR(uint256 _SCR) external override onlyOwner {
        config.SCR = _SCR;
        emit SCRUpdated(_SCR);
    }

    function setLCR(uint256 _LCR) external override onlyOwner {
        config.LCR = _LCR;
        emit LCRUpdated(_LCR);
    }

    function setMinDebt(uint256 _minDebt) external override onlyOwner {
        config.minDebt = _minDebt;
        emit MinDebtUpdated(_minDebt);
    }

    function setLiquidationPenaltyLiquidator(uint256 _liquidationPenaltyLiquidator) external override onlyOwner {
        config.liquidationPenaltyLiquidator = _liquidationPenaltyLiquidator;
        emit LiquidationPenaltyLiquidatorUpdated(_liquidationPenaltyLiquidator);
    }

    function setLiquidationPenaltySp(uint256 _liquidationPenaltySp) external override onlyOwner {
        config.liquidationPenaltySp = _liquidationPenaltySp;
        emit LiquidationPenaltySpUpdated(_liquidationPenaltySp);
    }

    function setLiquidationPenaltyDao(uint256 _liquidationPenaltyDao) external override onlyOwner {
        config.liquidationPenaltyDao = _liquidationPenaltyDao;
        emit LiquidationPenaltyDaoUpdated(_liquidationPenaltyDao);
    }

    function setLiquidationPenaltyDaoRecipient(address _liquidationPenaltyDaoRecipient) external override onlyOwner {
        _requireValidAddress(_liquidationPenaltyDaoRecipient);
        config.liquidationPenaltyDaoRecipient = _liquidationPenaltyDaoRecipient;
        emit LiquidationPenaltyDaoRecipientUpdated(_liquidationPenaltyDaoRecipient);
    }

    function setGasCompensation(uint256 _gasCompensation) external override onlyOwner {
        config.gasCompensation = _gasCompensation;
        emit GasCompensationUpdated(_gasCompensation);
    }

    // --- Getter Functions (View) ---

    function getConfig() external view override returns (Config memory) {
        return config;
    }

    function isFrozen() external view override returns (bool) {
        return config.isFrozen;
    }

    function isPaused() external view override returns (bool) {
        return config.isPaused;
    }

    function getAnnualInterestRate() external view override returns (uint256) {
        if (config.annualInterestRate == type(uint256).max) {
            return globalConfig.getConfig().annualInterestRate;
        }
        return config.annualInterestRate;
    }

    function getTreasury() external view override returns (address) {
        if (config.treasury == address(0)) {
            return globalConfig.getConfig().treasury;
        }
        return config.treasury;
    }

    function getBorrowRatio() external view override returns (uint256) {
        if (config.borrowRatio == type(uint256).max) {
            return globalConfig.getConfig().borrowRatio;
        }
        return config.borrowRatio;
    }

    function getMCR() external view override returns (uint256) {
        if (config.MCR == type(uint256).max){
            return globalConfig.getConfig().MCR;
        }
        return config.MCR;
    }

    function getCCR() external view override returns (uint256) {
        if (config.CCR == type(uint256).max) {
            return globalConfig.getConfig().CCR;
        }
        return config.CCR;
    }

    function getSCR() external view override returns (uint256) {
        if (config.SCR == type(uint256).max) {
            return globalConfig.getConfig().SCR;
        }
        return config.SCR;
    }

    function getLCR() external view override returns (uint256) {
        if (config.LCR == type(uint256).max) {
            return globalConfig.getConfig().LCR;
        }
        return config.LCR;
    }

    function getMinDebt() external view override returns (uint256) {
        if (config.minDebt == type(uint256).max) {
            return globalConfig.getConfig().minDebt;
        }
        return config.minDebt;
    }

    function getLiquidationPenaltyLiquidator() external view override returns (uint256) {
        if (config.liquidationPenaltyLiquidator == type(uint256).max) {
            return globalConfig.getConfig().liquidationPenaltyLiquidator;
        }
        return config.liquidationPenaltyLiquidator;
    }

    function getLiquidationPenaltySp() external view override returns (uint256) {
        if (config.liquidationPenaltySp == type(uint256).max) {
            return globalConfig.getConfig().liquidationPenaltySp;
        }
        return config.liquidationPenaltySp;
    }

    function getLiquidationPenaltyDao() external view override returns (uint256) {
        if (config.liquidationPenaltyDao == type(uint256).max) {
            return globalConfig.getConfig().liquidationPenaltyDao;
        }
        return config.liquidationPenaltyDao;
    }

    function getLiquidationPenaltyDaoRecipient() external view override returns (address) {
        if (config.liquidationPenaltyDaoRecipient == address(0)) {
            return globalConfig.getConfig().liquidationPenaltyDaoRecipient;
        }
        return config.liquidationPenaltyDaoRecipient;
    }

    function getGasCompensation() external view override returns (uint256) {
        if (config.gasCompensation == type(uint256).max) {
            return globalConfig.getConfig().gasCompensation;
        }
        return config.gasCompensation;
    }

    // --- Check Functions ---

    /**
     * @notice Check if operations are allowed
     * @param _isIncrease True for operations that increase exposure (open, add collateral/debt)
     * @dev Reverts if:
     *      - Collateral is paused (all operations blocked except close)
     *      - Collateral is frozen and operation increases exposure
     */
    function requireNotPausedOrFrozen(bool _isIncrease, bool _isDecrease) public view override {
        if (config.isPaused || globalConfig.getConfig().globalPaused) {
            revert CollateralPaused();
        }

        if (_isIncrease && (config.isFrozen || globalConfig.getConfig().mintPaused)) {
            revert CollateralFrozen();
        }

        if (_isDecrease && globalConfig.getConfig().redeemPaused) {
            revert CollateralFrozen();
        }
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

    function _requireTroveIsActive(ITroveManager _troveManager, uint256 _troveId) internal view {
        ITroveManager.Status status = _troveManager.getTroveStatus(_troveId);
        if (status != ITroveManager.Status.active) {
            revert TroveNotActive();
        }
    }
}
