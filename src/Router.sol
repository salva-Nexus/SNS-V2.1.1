// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Events } from "./utils/Events.sol";
import { Modifier } from "./utils/Modifier.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

abstract contract Router is Modifier, Events {
    using Clones for address;

    function _initializeRegistry(string memory nspace, address[] memory owners)
        internal
        returns (address clone)
    {
        clone = BaseRegistryImpl.clone();
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,address,address[])", nspace, address(this), owners
        );
        (bool initSuccess,) = clone.call(initData);
        if (!initSuccess) revert Singleton__RegistryInitFailed();
    }
}
