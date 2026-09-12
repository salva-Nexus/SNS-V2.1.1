// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Events {
    event RegistryInitialized(
        bytes32 indexed namespaceKey,
        address indexed registry,
        string namespaceHandle,
        address[] owners
    );

    event BaseRegistryImplUpdated(address indexed newBaseRegistryImpl);
    event NameLinked(bytes32 indexed node, bytes32 indexed data, address indexed operator);
    event NameUnlinked(bytes32 indexed node, address indexed operator);
}
