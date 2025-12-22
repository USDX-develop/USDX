//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "solady/utils/SSTORE2.sol";

import "./utils/JSON.sol";

import "./utils/baseSVG.sol";
import "./utils/bauhaus.sol";

import {ITroveManager} from "../Interfaces/ITroveManager.sol";

interface IMetadataNFT {
    struct TroveData {
        uint256 _tokenId;
        address _owner;
        address _collToken;
        address _usdxToken;
        uint256 _collAmount;
        uint256 _debtAmount;
        uint256 _interestRate;
        ITroveManager.Status _status;
    }

    function uri(
        TroveData memory _troveData
    ) external view returns (string memory);
}

contract MetadataNFT is IMetadataNFT {

    constructor(
    ) {
    }

    function uri(
        TroveData memory _troveData
    ) public view returns (string memory) {
        string memory attr = attributes(_troveData);
        return
            json.formattedMetadata(
                string.concat(
                    "USDX - ",
                    IERC20Metadata(_troveData._collToken).name()
                ),
                string.concat(
                    "USDX is a collateralized debt platform. Users can lock up ",
                    IERC20Metadata(_troveData._collToken).symbol(),
                    " to issue stablecoin tokens (USDX) to their own Ethereum address. The individual collateralized debt positions are called Troves, and are represented as NFTs."
                ),
                "",
                attr
            );
    }

    function attributes(
        TroveData memory _troveData
    ) public pure returns (string memory) {
        //include: collateral token address, collateral amount, debt token address, debt amount, interest rate, status
        return
            string.concat(
                '[{"trait_type": "Collateral Token", "value": "',
                LibString.toHexString(_troveData._collToken),
                '"}, {"trait_type": "Collateral Amount", "value": "',
                LibString.toString(_troveData._collAmount),
                '"}, {"trait_type": "Debt Token", "value": "',
                LibString.toHexString(_troveData._usdxToken),
                '"}, {"trait_type": "Debt Amount", "value": "',
                LibString.toString(_troveData._debtAmount),
                '"}, {"trait_type": "Interest Rate", "value": "',
                LibString.toString(_troveData._interestRate),
                '"}, {"trait_type": "Status", "value": "',
                _status2Str(_troveData._status),
                '"} ]'
            );
    }

    function _status2Str(
        ITroveManager.Status status
    ) internal pure returns (string memory) {
        if (status == ITroveManager.Status.active) return "Active";
        if (status == ITroveManager.Status.closedByOwner) return "Closed";
        if (status == ITroveManager.Status.closedByLiquidation)
            return "Liquidated";
        if (status == ITroveManager.Status.zombie) return "Below Min Debt";
        return "";
    }
}
