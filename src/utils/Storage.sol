// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Storage {
    address internal immutable MULTISIG;
    address internal BaseRegistryImpl;

    struct NamespaceConfig {
        address registryAddress;
        uint96 handleLength;
    }

    mapping(bytes32 => NamespaceConfig) internal _namespaceConfigs;
}
