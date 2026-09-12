// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IBaseRegistry {
    error BaseRegistry__NotAllowed();
    error BaseRegistry__InvalidInput();
    error BaseRegistry__NameTaken();

    event Initialized(string namespace, address singleton, address[] owners);
    event OwnerAdded(address indexed owner);
    event RecordLinked(bytes32 indexed node, bytes32 data);
    event RecordUnlinked(bytes32 indexed node);

    // Initializer
    function initialize(
        string calldata namespaceHandle,
        address singleton_,
        address[] calldata owners_
    ) external;

    // State Variable Getters (MUST be external)
    function singleton() external view returns (address);
    function namespace() external view returns (string memory);
    function isOwner(address account) external view returns (bool);
    function owners() external view returns (uint256);

    // Mutative Functions
    function link(bytes32 node, bytes32 data) external returns (bool);
    function unlink(bytes32 node) external returns (bool);

    // View Functions
    function resolve(bytes32 node) external view returns (bytes32);
    function resolveToAddr(bytes32 node) external view returns (address);
}
