// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { IBaseRegistry } from "../src/interfaces/IBaseRegistry.sol";
import { Test } from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    BaseRegistry public baseRegistryImpl;
    Singleton public singleton;
    BaseRegistry public registryClone;

    address public multisig = makeAddr("multisig");
    address public owner1 = makeAddr("owner1");
    address public owner2 = makeAddr("owner2");
    address public alice = makeAddr("alice");

    string public constant NAMESPACE = "@salva";
    bytes public constant NAME_ALICE = bytes("alice");
    bytes public constant SAMPLE_DATA = abi.encode(address(0x1234));

    function setUp() public virtual {
        baseRegistryImpl = new BaseRegistry();

        singleton = new Singleton(multisig, address(baseRegistryImpl));
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        _changePrank(multisig);
        registryClone = BaseRegistry(singleton.initializeRegistry(NAMESPACE, owners));
        _stopPrank();
    }

    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }
}
