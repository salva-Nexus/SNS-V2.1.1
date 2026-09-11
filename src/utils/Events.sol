// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Events {
    event RegistryInitialized(
        bytes32 indexed namespaceKey,
        address indexed registry,
        string namespaceHandle,
        address[] owners
    );
}
