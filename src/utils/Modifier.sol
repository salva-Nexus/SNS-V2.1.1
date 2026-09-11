// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "./Errors.sol";
import { Storage } from "./Storage.sol";

abstract contract Modifier is Storage, Errors {
    modifier onlyMultiSig() {
        if (msg.sender != MULTISIG) revert Singleton__NotMultiSig();
        _;
    }
}
