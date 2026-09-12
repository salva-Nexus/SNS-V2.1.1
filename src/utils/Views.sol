// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Modifier } from "./Modifier.sol";

abstract contract Views is Modifier {
    function registry(bytes4 nsKey) public view returns (address) {
        return _nsKeyToAddress[nsKey];
    }

    function key(bytes memory nspace) public pure returns (bytes4) {
        return bytes4(keccak256(nspace));
    }

    function stringToBytes(string memory nspace) public pure returns (bytes memory) {
        return bytes(nspace);
    }
}
