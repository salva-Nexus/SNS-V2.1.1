// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IBaseRegistry {
    error BaseRegistry__NotSingleton();
    error BaseRegistry__InvalidInput();

    event Initialized(string namespace, address router, address[] owners);
    event RecordLinked(bytes32 indexed nameHash, bytes data);
    event RecordUnlinked(bytes32 indexed nameHash);
    event OwnerAdded(address indexed owner);

    function initialize(string calldata namespaceHandle, address router, address[] calldata owners)
        external;
    function link(bytes calldata name, bytes calldata data) external returns (bool);
    function unlink(bytes calldata name) external returns (bool);
    function resolve(bytes calldata name) external view returns (bytes memory);
}
