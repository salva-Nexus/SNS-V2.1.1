// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Errors {
    error Singleton__NotMultiSig();
    error Singleton__NotAllowed();
    error Singleton__InvalidNamespaceFormat();
    error Singleton__DoubleInitialization();
    error Singleton__RegistryInitFailed();
    error Singleton__InvalidAddress();
    error Singleton__NspaceNotRegistered();
}
