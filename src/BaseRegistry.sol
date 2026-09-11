// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IBaseRegistry } from "./interfaces/IBaseRegistry.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract BaseRegistry is IBaseRegistry, Initializable {
    address public singleton;
    string public namespace;
    mapping(address => bool) public isOwner;
    mapping(bytes32 => bytes) private _records;

    modifier onlySingleton() {
        if (msg.sender != singleton) revert BaseRegistry__NotSingleton();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata namespaceHandle,
        address singleton_,
        address[] calldata owners
    ) external initializer {
        if (singleton_ == address(0)) revert BaseRegistry__InvalidInput();

        namespace = namespaceHandle;
        singleton = singleton_;

        uint256 len = owners.length;
        for (uint256 i = 0; i < len;) {
            address owner = owners[i];
            if (owner != address(0)) {
                isOwner[owner] = true;
                emit OwnerAdded(owner);
            }
            unchecked {
                i++;
            }
        }

        emit Initialized(namespaceHandle, singleton_, owners);
    }

    function link(bytes calldata name, bytes calldata data) external onlySingleton returns (bool) {
        bytes32 nameHash = keccak256(name);
        _records[nameHash] = data;

        emit RecordLinked(nameHash, data);
        return true;
    }

    function unlink(bytes calldata name) external onlySingleton returns (bool) {
        bytes32 nameHash = keccak256(name);
        delete _records[nameHash];

        emit RecordUnlinked(nameHash);
        return true;
    }

    function resolve(bytes calldata name) external view returns (bytes memory) {
        return _records[keccak256(name)];
    }

    function resolveToAddr(bytes calldata name) external view returns (address) {
        bytes memory data = _records[keccak256(name)];
        if (data.length < 20) return address(0);
        return abi.decode(data, (address));
    }
}
