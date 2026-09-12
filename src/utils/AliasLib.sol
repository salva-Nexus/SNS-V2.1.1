// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IBaseRegistry } from "../interfaces/IBaseRegistry.sol";
import { Context } from "./Context.sol";
import { Errors } from "./Errors.sol";
import { Storage } from "./Storage.sol";

abstract contract AliasLib is Errors, Storage, Context {
    function _verifyOwnership(bytes4 nsKey) internal view returns (address) {
        address registry = _nsKeyToAddress[nsKey];
        if (registry == address(0)) {
            revert Singleton__NspaceNotRegistered();
        }
        uint256 owners = IBaseRegistry(registry).owners();
        // Public registries do now have owners
        if (owners > 0) {
            bool isOwner = IBaseRegistry(registry).isOwner(_msgSender());
            if (!isOwner) revert Singleton__NotAllowed();
        }
        return registry;
    }

    function _computeNode(bytes32 nameHash, bytes4 nsKey) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nameHash, nsKey));
    }

    function _execute(address registry, bytes32 finalHash, bytes32 data) internal {
        if (data != bytes32(0)) IBaseRegistry(registry).link(finalHash, data);
        else IBaseRegistry(registry).unlink(finalHash);
    }

    function _resolve(bytes32 nameHash, bytes4 nsKey) internal view returns (bytes32) {
        address registry = _nsKeyToAddress[nsKey];
        if (registry == address(0)) return bytes32(0);
        bytes32 node = _computeNode(nameHash, nsKey);
        return IBaseRegistry(registry).resolve(node);
    }
}
