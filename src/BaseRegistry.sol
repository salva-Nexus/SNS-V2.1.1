// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IBaseRegistry } from "./interfaces/IBaseRegistry.sol";
import { Context } from "./utils/Context.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract BaseRegistry is IBaseRegistry, Initializable, Context {
    address public singleton;
    string public namespace;
    address[] private owners;
    mapping(address => bool) public isOwner;
    mapping(bytes32 => bytes32) private _records;

    modifier onlyAuthorized() {
        if (_msgSender() != singleton && !isOwner[_msgSender()]) revert BaseRegistry__NotAllowed();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata namespaceHandle,
        address singleton_,
        address[] calldata owners_
    ) external initializer {
        if (singleton_ == address(0)) revert BaseRegistry__InvalidInput();

        namespace = namespaceHandle;
        singleton = singleton_;

        uint256 len = owners_.length;
        if (len == 0) revert BaseRegistry__MustInitializeWithAnOwner();
        if (len > 0) {
            for (uint256 i = 0; i < len;) {
                address owner = owners_[i];
                if (owner != address(0)) {
                    isOwner[owner] = true;
                    owners.push(owner);
                    emit OwnerAdded(owner);
                }
                unchecked {
                    i++;
                }
            }
        }
        emit Initialized(namespaceHandle, singleton_, owners_);
    }

    // Using assembly to avoid another hashing since node is already a hash of name + namespace
    function link(bytes32 node, bytes32 data) external onlyAuthorized returns (bool) {
        bytes32 linkedData;
        assembly ("memory-safe") {
            linkedData := sload(node)
        }
        if (linkedData != bytes32(0)) revert BaseRegistry__NameTaken();
        assembly ("memory-safe") {
            sstore(node, data)
        }
        emit RecordLinked(node, data);
        return true;
    }

    function unlink(bytes32 node) external onlyAuthorized returns (bool) {
        assembly ("memory-safe") {
            sstore(node, 0)
        }
        emit RecordUnlinked(node);
        return true;
    }

    function resolve(bytes32 node) external view returns (bytes32 data) {
        assembly ("memory-safe") {
            data := sload(node)
        }
    }

    function resolveToAddr(bytes32 node) external view returns (address addr) {
        assembly ("memory-safe") {
            addr := and(sload(node), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }
}
