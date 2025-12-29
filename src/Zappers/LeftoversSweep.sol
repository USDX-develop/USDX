// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Interfaces/IUSDXToken.sol";

contract LeftoversSweep {
    using SafeERC20 for IERC20;

    struct InitialBalances {
        address[4] tokens; // paving the way for completely dynamic routes
        uint256[4] balances;
        address receiver;
    }

    function _setInitialTokensAndBalances(
        IERC20 _collToken,
        IUSDXToken _usdxToken,
        InitialBalances memory _initialBalances
    ) internal view {
        _setInitialTokensBalancesAndReceiver(_collToken, _usdxToken, _initialBalances, msg.sender);
    }

    function _setInitialTokensBalancesAndReceiver(
        IERC20 _collToken,
        IUSDXToken _usdxToken,
        InitialBalances memory _initialBalances,
        address _receiver
    ) internal view {
        _initialBalances.tokens[0] = address(_collToken);
        _initialBalances.tokens[1] = address(_usdxToken);
        _setInitialBalancesAndReceiver(_initialBalances, _receiver);
    }

    function _setInitialBalances(InitialBalances memory _initialBalances) internal view {
        _setInitialBalancesAndReceiver(_initialBalances, msg.sender);
    }

    function _setInitialBalancesAndReceiver(InitialBalances memory _initialBalances, address _receiver) internal view {
        for (uint256 i = 0; i < _initialBalances.tokens.length; i++) {
            if (_initialBalances.tokens[i] == address(0)) break;

            _initialBalances.balances[i] = IERC20(_initialBalances.tokens[i]).balanceOf(address(this));
        }
        _initialBalances.receiver = _receiver;
    }

    function _returnLeftovers(InitialBalances memory _initialBalances) internal {
        for (uint256 i = 0; i < _initialBalances.tokens.length; i++) {
            if (_initialBalances.tokens[i] == address(0)) break;

            uint256 currentBalance = IERC20(_initialBalances.tokens[i]).balanceOf(address(this));
            if (currentBalance > _initialBalances.balances[i]) {
                IERC20(_initialBalances.tokens[i]).safeTransfer(
                    _initialBalances.receiver, currentBalance - _initialBalances.balances[i]
                );
            }
        }
    }
}
