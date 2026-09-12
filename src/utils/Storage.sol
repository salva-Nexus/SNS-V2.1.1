// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Storage {
    address public MULTISIG;
    address public BaseRegistryImpl;
    mapping(bytes4 => address) internal _nsKeyToAddress;
    uint256[50] private __gap;
}
