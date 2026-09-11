// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Errors } from "../src/utils/Errors.sol";
import { BaseTest } from "./BaseTest.t.sol";

contract Singleton is BaseTest {
    function test_InitializeRegistry_Success() public view {
        assertEq(registryClone.namespace(), NAMESPACE);
        assertEq(registryClone.singleton(), address(singleton));
        assertTrue(registryClone.isOwner(owner1));
        assertTrue(registryClone.isOwner(owner2));
    }

    function test_Revert_InitializeRegistry_NotMultisig() public {
        address[] memory owners = new address[](1);
        owners[0] = alice;

        _changePrank(alice);
        vm.expectRevert(Errors.Singleton__NotMultiSig.selector);
        singleton.initializeRegistry("@test", owners);
        _stopPrank();
    }

    function test_Revert_InitializeRegistry_InvalidNamespace() public {
        address[] memory owners = new address[](1);
        owners[0] = owner1;

        _changePrank(multisig);

        vm.expectRevert(Errors.Singleton__InvalidNamespaceFormat.selector);
        singleton.initializeRegistry("salva", owners);

        vm.expectRevert(Errors.Singleton__InvalidNamespaceFormat.selector);
        singleton.initializeRegistry("", owners);

        vm.expectRevert(Errors.Singleton__InvalidNamespaceFormat.selector);
        singleton.initializeRegistry("@thisnamespaceiswaytoolongandexceedsthirtytwobytes", owners);

        _stopPrank();
    }

    function test_Revert_InitializeRegistry_DoubleInitialization() public {
        address[] memory owners = new address[](1);
        owners[0] = owner1;

        _changePrank(multisig);
        vm.expectRevert(Errors.Singleton__DoubleInitialization.selector);
        singleton.initializeRegistry(NAMESPACE, owners);
        _stopPrank();
    }
}
