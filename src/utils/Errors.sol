// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Errors {
    error Singleton__NotMultiSig();
    error Singleton__InvalidNamespaceFormat();
    error Singleton__DoubleInitialization();
    error Singleton__RegistryInitFailed();
}
