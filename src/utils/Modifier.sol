// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AliasLib } from "./AliasLib.sol";

abstract contract Modifier is AliasLib {
    modifier onlyMultiSig() {
        if (_msgSender() != MULTISIG) revert Singleton__NotMultiSig();
        _;
    }
}
