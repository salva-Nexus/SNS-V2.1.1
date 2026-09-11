// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Router } from "./Router.sol";

contract Singleton is Router {
    constructor(address multisig, address baseRegistryImpl) {
        MULTISIG = multisig;
        BaseRegistryImpl = baseRegistryImpl;
    }

    function initializeRegistry(string memory namespaceHandle, address[] memory owners)
        external
        payable
        onlyMultiSig
        returns (address registry)
    {
        bytes memory nsBytes = bytes(namespaceHandle);

        // Ensure non-empty, max 32 bytes (0x20), and starts with '@' (0x40)
        if (nsBytes.length == 0 || nsBytes.length > 32 || nsBytes[0] != 0x40) {
            revert Singleton__InvalidNamespaceFormat();
        }

        // Hash namespace string for mapping key
        bytes32 nsKey = keccak256(nsBytes);
        NamespaceConfig storage nData = _namespaceConfigs[nsKey];

        if (nData.registryAddress != address(0)) {
            revert Singleton__DoubleInitialization();
        }

        registry = _initializeRegistry(namespaceHandle, owners);
        nData.registryAddress = registry;
        nData.handleLength = uint96(nsBytes.length);

        emit RegistryInitialized(nsKey, registry, namespaceHandle, owners);
    }
}
