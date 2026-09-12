// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IBaseRegistry } from "./interfaces/IBaseRegistry.sol";
import { Context } from "./utils/Context.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract BaseRegistry is IBaseRegistry, Initializable, Context {
    address public singleton;
    string public namespace;
    uint256 public owners;
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
        if (len > 0) {
            for (uint256 i = 0; i < len;) {
                address owner = owners_[i];
                if (owner != address(0)) {
                    isOwner[owner] = true;
                    owners++;
                    emit OwnerAdded(owner);
                }
                unchecked {
                    i++;
                }
            }
        }

        emit Initialized(namespaceHandle, singleton_, owners_);
    }

    function link(bytes32 node, bytes32 data) external onlyAuthorized returns (bool) {
        bytes32 linkedData = _records[node];
        if (linkedData != bytes32(0)) revert BaseRegistry__NameTaken();
        _records[node] = data;
        emit RecordLinked(node, data);
        return true;
    }

    function unlink(bytes32 node) external onlyAuthorized returns (bool) {
        delete _records[node];
        emit RecordUnlinked(node);
        return true;
    }

    function resolve(bytes32 node) external view returns (bytes32) {
        return _records[node];
    }

    function resolveToAddr(bytes32 node) external view returns (address) {
        return address(uint160(uint256(_records[node])));
    }
}
