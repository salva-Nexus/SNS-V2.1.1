// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Events } from "../utils/Events.sol";
import { Views } from "../utils/Views.sol";

abstract contract Name is Views, Events {
    function link(bytes32 nameHash, bytes4 nsKey, bytes32 data) external returns (bool) {
        // nameHash = hash of name, eg => keccak(cboi), keccak(pay.alice),
        // keccask(pay.usdc.arbitrum)
        address registry = _verifyOwnership(nsKey);
        bytes32 node = _computeNode(nameHash, nsKey);
        _execute(registry, node, data);
        emit NameLinked(node, data, _msgSender());
        return true;
    }

    function unlink(bytes32 nameHash, bytes4 nsKey) external returns (bool) {
        address registry = _verifyOwnership(nsKey);
        bytes32 node = _computeNode(nameHash, nsKey);
        _execute(registry, node, bytes32(0));
        emit NameUnlinked(node, _msgSender());
        return true;
    }

    function resolveAddr(bytes32 nameHash, bytes4 nsKey) external view returns (address) {
        bytes32 data = _resolve(nameHash, nsKey);
        return address(uint160(uint256(data)));
    }

    function resolve(bytes32 nameHash, bytes4 nsKey) external view returns (bytes32) {
        return _resolve(nameHash, nsKey);
    }
}
