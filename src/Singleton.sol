// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Router } from "./Router.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Singleton is Router, Initializable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address multisig) external initializer {
        if (multisig == address(0)) {
            revert Singleton__InvalidAddress();
        }

        MULTISIG = multisig;
    }

    function setBaseRegistryImpl(address newBaseRegistryImpl) external onlyMultiSig {
        if (newBaseRegistryImpl == address(0)) {
            revert Singleton__InvalidAddress();
        }

        emit BaseRegistryImplUpdated(newBaseRegistryImpl);
        BaseRegistryImpl = newBaseRegistryImpl;
    }

    function initializeRegistry(string memory namespaceHandle, address[] memory owners)
        public
        payable
        onlyMultiSig
        returns (address registryAddr)
    {
        bytes memory nsBytes = bytes(namespaceHandle);

        // Ensure non-empty, max 32 bytes (0x20), and starts with '@' (0x40)
        if (nsBytes.length == 0 || nsBytes.length > 0x20 || nsBytes[0] != 0x40) {
            revert Singleton__InvalidNamespaceFormat();
        }

        // Hash namespace string for mapping key
        bytes4 nsKey = key(nsBytes);
        address initializedRegistry = registry(nsKey);

        if (initializedRegistry != address(0)) {
            revert Singleton__DoubleInitialization();
        }

        registryAddr = _initializeRegistry(namespaceHandle, owners);
        _nsKeyToAddress[nsKey] = registryAddr;
        emit RegistryInitialized(nsKey, registryAddr, namespaceHandle, owners);
    }

    function reInitializeRegistry(string memory namespaceHandle, address[] memory owners)
        public
        payable
        onlyMultiSig
        returns (address registryAddr)
    {
        bytes memory nsBytes = bytes(namespaceHandle);
        if (nsBytes.length == 0 || nsBytes.length > 0x20 || nsBytes[0] != 0x40) {
            revert Singleton__InvalidNamespaceFormat();
        }

        bytes4 nsKey = key(nsBytes);
        registryAddr = _initializeRegistry(namespaceHandle, owners);
        _nsKeyToAddress[nsKey] = registryAddr;
        emit RegistryInitialized(nsKey, registryAddr, namespaceHandle, owners);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyMultiSig { }
}
