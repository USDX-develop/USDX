// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import {MIN_LIQUIDATION_PENALTY_SP, MAX_LIQUIDATION_PENALTY_REDISTRIBUTION} from "./Dependencies/Constants.sol";
import "./Interfaces/IAddressesRegistry.sol";

contract AddressesRegistry is
Initializable,
OwnableUpgradeable,
UUPSUpgradeable,
IAddressesRegistry
{
    IERC20Metadata public collToken;
    IBorrowerOperations public borrowerOperations;
    ITroveManager public troveManager;
    ITroveNFT public troveNFT;
    IMetadataNFT public metadataNFT;
    IStabilityPool public stabilityPool;
    IPriceFeed public priceFeed;
    IActivePool public activePool;
    IDefaultPool public defaultPool;
    address public gasPoolAddress;
    ICollSurplusPool public collSurplusPool;
    ISortedTroves public sortedTroves;
    IInterestRouter public interestRouter;
    IHintHelpers public hintHelpers;
    IMultiTroveGetter public multiTroveGetter;
    ICollateralRegistry public collateralRegistry;
    IUSDXToken public usdxToken;
    IWETH public WETH;
    ICollateralConfig public collateralConfig;

    error InvalidCCR();
    error InvalidMCR();
    error InvalidBCR();
    error InvalidSCR();
    error SPPenaltyTooLow();
    error SPPenaltyGtRedist();
    error RedistPenaltyTooHigh();

    event CollTokenAddressChanged(address _collTokenAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event TroveManagerAddressChanged(address _troveManagerAddress);
    event TroveNFTAddressChanged(address _troveNFTAddress);
    event MetadataNFTAddressChanged(address _metadataNFTAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event PriceFeedAddressChanged(address _priceFeedAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event InterestRouterAddressChanged(address _interestRouterAddress);
    event HintHelpersAddressChanged(address _hintHelpersAddress);
    event MultiTroveGetterAddressChanged(address _multiTroveGetterAddress);
    event CollateralRegistryAddressChanged(address _collateralRegistryAddress);
    event USDXTokenAddressChanged(address _usdxTokenAddress);
    event WETHAddressChanged(address _wethAddress);
    event CollateralConfigAddressChanged(address _collateralConfigAddress);

    constructor(
    ) {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        IWETH _weth,
        IERC20Metadata _collToken
    ) public initializer {
        __Ownable_init();
        transferOwnership(initialOwner);
        WETH = _weth;
        collToken = _collToken;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function setAddresses(AddressVars memory _vars) external onlyOwner {
        collToken = _vars.collToken;
        borrowerOperations = _vars.borrowerOperations;
        troveManager = _vars.troveManager;
        troveNFT = _vars.troveNFT;
        metadataNFT = _vars.metadataNFT;
        stabilityPool = _vars.stabilityPool;
        priceFeed = _vars.priceFeed;
        activePool = _vars.activePool;
        defaultPool = _vars.defaultPool;
        gasPoolAddress = _vars.gasPoolAddress;
        collSurplusPool = _vars.collSurplusPool;
        sortedTroves = _vars.sortedTroves;
        interestRouter = _vars.interestRouter;
        hintHelpers = _vars.hintHelpers;
        multiTroveGetter = _vars.multiTroveGetter;
        collateralRegistry = _vars.collateralRegistry;
        usdxToken = _vars.usdxToken;
        collateralConfig = _vars.collateralConfig;

        emit CollTokenAddressChanged(address(_vars.collToken));
        emit BorrowerOperationsAddressChanged(
            address(_vars.borrowerOperations)
        );
        emit TroveManagerAddressChanged(address(_vars.troveManager));
        emit TroveNFTAddressChanged(address(_vars.troveNFT));
        emit MetadataNFTAddressChanged(address(_vars.metadataNFT));
        emit StabilityPoolAddressChanged(address(_vars.stabilityPool));
        emit PriceFeedAddressChanged(address(_vars.priceFeed));
        emit ActivePoolAddressChanged(address(_vars.activePool));
        emit DefaultPoolAddressChanged(address(_vars.defaultPool));
        emit GasPoolAddressChanged(_vars.gasPoolAddress);
        emit CollSurplusPoolAddressChanged(address(_vars.collSurplusPool));
        emit SortedTrovesAddressChanged(address(_vars.sortedTroves));
        emit InterestRouterAddressChanged(address(_vars.interestRouter));
        emit HintHelpersAddressChanged(address(_vars.hintHelpers));
        emit MultiTroveGetterAddressChanged(address(_vars.multiTroveGetter));
        emit CollateralRegistryAddressChanged(
            address(_vars.collateralRegistry)
        );
        emit USDXTokenAddressChanged(address(_vars.usdxToken));
        emit CollateralConfigAddressChanged(address(_vars.collateralConfig));
    }
}
