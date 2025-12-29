// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.28;

interface IZapper {
    struct OpenTroveParams {
        address owner;
        uint256 ownerIndex;
        uint256 collAmount;
        uint256 usdxAmount;
        uint256 upperHint;
        uint256 lowerHint;
        address addManager;
        address removeManager;
        address receiver;
    }

    struct CloseTroveParams {
        uint256 troveId;
        uint256 minExpectedCollateral;
        address receiver;
    }

    function openTroveWithRawETH(OpenTroveParams calldata _params) external payable returns (uint256);
}
