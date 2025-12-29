// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

import "./BaseZapper.sol";
import "../Dependencies/Constants.sol";

contract WXOCZapper is Initializable, OwnableUpgradeable, UUPSUpgradeable, BaseZapper {
    constructor(IAddressesRegistry _addressesRegistry)
        BaseZapper(_addressesRegistry)
    {
        _disableInitializers();
        require(address(WETH) == address(_addressesRegistry.collToken()), "WZ: Wrong coll branch");
        // Approve coll to BorrowerOperations
        WETH.approve(address(borrowerOperations), type(uint256).max);
    }

    function initialize(address initialOwner, IAddressesRegistry _addressesRegistry) public initializer {
        __Ownable_init();
        __BaseZapper_init(_addressesRegistry);
        transferOwnership(initialOwner);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function openTroveWithRawETH(OpenTroveParams calldata _params) external payable returns (uint256) {
        require(msg.value > ETH_GAS_COMPENSATION, "WZ: Insufficient ETH");

        // Convert ETH to WETH
        WETH.deposit{value: msg.value}();

        uint256 troveId;
        // Include sender in index
        uint256 index = _getTroveIndex(_params.ownerIndex);
        troveId = borrowerOperations.openTrove(
            _params.owner,
            index,
            msg.value - ETH_GAS_COMPENSATION,
            _params.usdxAmount,
            _params.upperHint,
            _params.lowerHint,
            // Add this contract as add/receive manager to be able to fully adjust trove,
            // while keeping the same management functionality
            address(this), // add manager
            address(this), // remove manager
            address(this) // receiver for remove manager
        );

        usdxToken.transfer(msg.sender, _params.usdxAmount);

        // Set add/remove managers
        _setAddManager(troveId, _params.addManager);
        _setRemoveManagerAndReceiver(troveId, _params.removeManager, _params.receiver);

        return troveId;
    }

    function addCollWithRawETH(uint256 _troveId) external payable {
        address owner = troveNFT.ownerOf(_troveId);
        _requireSenderIsOwnerOrAddManager(_troveId, owner);
        // Convert ETH to WETH
        WETH.deposit{value: msg.value}();

        borrowerOperations.addColl(_troveId, msg.value);
    }

    function withdrawCollToRawETH(uint256 _troveId, uint256 _amount) external {
        address owner = troveNFT.ownerOf(_troveId);
        address payable receiver = payable(_requireSenderIsOwnerOrRemoveManagerAndGetReceiver(_troveId, owner));
        _requireZapperIsReceiver(_troveId);

        borrowerOperations.withdrawColl(_troveId, _amount);

        // Convert WETH to ETH
        WETH.withdraw(_amount);
        (bool success,) = receiver.call{value: _amount}("");
        require(success, "WZ: Sending ETH failed");
    }

    function withdrawUSDX(uint256 _troveId, uint256 _usdxAmount, uint256 _maxUpfrontFee) external {
        address owner = troveNFT.ownerOf(_troveId);
        address receiver = _requireSenderIsOwnerOrRemoveManagerAndGetReceiver(_troveId, owner);
        _requireZapperIsReceiver(_troveId);

        borrowerOperations.withdrawUSDX(_troveId, _usdxAmount);

        // Send USDX
        usdxToken.transfer(receiver, _usdxAmount);
    }

    function repayUSDX(uint256 _troveId, uint256 _usdxAmount) external {
        address owner = troveNFT.ownerOf(_troveId);
        _requireSenderIsOwnerOrAddManager(_troveId, owner);

        // Set initial balances to make sure there are not lefovers
        InitialBalances memory initialBalances;
        _setInitialTokensAndBalances(WETH, usdxToken, initialBalances);

        // Pull USDX
        usdxToken.transferFrom(msg.sender, address(this), _usdxAmount);

        borrowerOperations.repayUSDX(_troveId, _usdxAmount);

        // return leftovers to user
        _returnLeftovers(initialBalances);
    }

    function adjustTroveWithRawETH(
        uint256 _troveId,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _usdxChange,
        bool _isDebtIncrease,
        uint256 _maxUpfrontFee
    ) external payable {
        InitialBalances memory initialBalances;
        address payable receiver =
            _adjustTrovePre(_troveId, _collChange, _isCollIncrease, _usdxChange, _isDebtIncrease, initialBalances);
        borrowerOperations.adjustTrove(
            _troveId, _collChange, _isCollIncrease, _usdxChange, _isDebtIncrease
        );
        _adjustTrovePost(_collChange, _isCollIncrease, _usdxChange, _isDebtIncrease, receiver, initialBalances);
    }

    function adjustZombieTroveWithRawETH(
        uint256 _troveId,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _usdxChange,
        bool _isDebtIncrease,
        uint256 _upperHint,
        uint256 _lowerHint,
        uint256 _maxUpfrontFee
    ) external payable {
        InitialBalances memory initialBalances;
        address payable receiver =
            _adjustTrovePre(_troveId, _collChange, _isCollIncrease, _usdxChange, _isDebtIncrease, initialBalances);
        borrowerOperations.adjustZombieTrove(
            _troveId, _collChange, _isCollIncrease, _usdxChange, _isDebtIncrease, _upperHint, _lowerHint
        );
        _adjustTrovePost(_collChange, _isCollIncrease, _usdxChange, _isDebtIncrease, receiver, initialBalances);
    }

    function _adjustTrovePre(
        uint256 _troveId,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _usdxChange,
        bool _isDebtIncrease,
        InitialBalances memory _initialBalances
    ) internal returns (address payable) {
        if (_isCollIncrease) {
            require(_collChange == msg.value, "WZ: Wrong coll amount");
        } else {
            require(msg.value == 0, "WZ: Not adding coll, no ETH should be received");
        }

        address payable receiver =
            payable(_checkAdjustTroveManagers(_troveId, _collChange, _isCollIncrease, _isDebtIncrease));

        // Set initial balances to make sure there are not lefovers
        _setInitialTokensAndBalances(WETH, usdxToken, _initialBalances);

        // ETH -> WETH
        if (_isCollIncrease) {
            WETH.deposit{value: _collChange}();
        }

        // Pull USDX
        if (!_isDebtIncrease) {
            usdxToken.transferFrom(msg.sender, address(this), _usdxChange);
        }

        return receiver;
    }

    function _adjustTrovePost(
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _usdxChange,
        bool _isDebtIncrease,
        address payable _receiver,
        InitialBalances memory _initialBalances
    ) internal {
        // Send USDX
        if (_isDebtIncrease) {
            usdxToken.transfer(_receiver, _usdxChange);
        }

        // return USDX leftovers to user (trying to repay more than possible)
        uint256 currentUSDXBalance = usdxToken.balanceOf(address(this));
        if (currentUSDXBalance > _initialBalances.balances[1]) {
            usdxToken.transfer(_initialBalances.receiver, currentUSDXBalance - _initialBalances.balances[1]);
        }
        // There shouldn’t be Collateral leftovers, everything sent should end up in the trove
        // But ETH and WETH balance can be non-zero if someone accidentally send it to this contract

        // WETH -> ETH
        if (!_isCollIncrease && _collChange > 0) {
            WETH.withdraw(_collChange);
            (bool success,) = _receiver.call{value: _collChange}("");
            require(success, "WZ: Sending ETH failed");
        }
    }

    function closeTroveToRawETH(uint256 _troveId) external {
        address owner = troveNFT.ownerOf(_troveId);
        address payable receiver = payable(_requireSenderIsOwnerOrRemoveManagerAndGetReceiver(_troveId, owner));
        _requireZapperIsReceiver(_troveId);

        // pull USDX for repayment
        LatestTroveData memory trove = troveManager.getLatestTroveData(_troveId);
        usdxToken.transferFrom(msg.sender, address(this), trove.entireDebt);

        borrowerOperations.closeTrove(_troveId);

        WETH.withdraw(trove.entireColl + ETH_GAS_COMPENSATION);
        (bool success,) = receiver.call{value: trove.entireColl + ETH_GAS_COMPENSATION}("");
        require(success, "WZ: Sending ETH failed");
    }

    receive() external payable {}
}
