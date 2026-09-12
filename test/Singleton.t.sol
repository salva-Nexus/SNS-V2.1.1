// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Errors } from "../src/utils/Errors.sol";
import { BaseTest } from "./BaseTest.t.sol";

contract Singleton is BaseTest {
    function test_InitializeRegistry_Success() public view {
        assertEq(publicRegistryClone.namespace(), PUBLIC_NAMESPACE);
        assertEq(publicRegistryClone.singleton(), address(singleton));
        assertEq(publicRegistryClone.owners(), 0);
    }

    function test_Revert_InitializeRegistry_NotMultisig() public {
        address[] memory owners = new address[](0);
        _changePrank(alice);
        vm.expectRevert(Errors.Singleton__NotMultiSig.selector);
        singleton.initializeRegistry("@test", owners);
        _stopPrank();
    }

    function test_Revert_InitializeRegistry_InvalidNamespace() public {
        address[] memory owners = new address[](0);
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
        address[] memory owners = new address[](0);

        _changePrank(multisig);
        vm.expectRevert(Errors.Singleton__DoubleInitialization.selector);
        singleton.initializeRegistry(PUBLIC_NAMESPACE, owners);
        _stopPrank();
    }

    function test_InitializeRegistry_PrivateNamespace_Success() public init {
        assertEq(privateRegistryClone.namespace(), PRIVATE_NAMESPACE);
        assertEq(privateRegistryClone.singleton(), address(singleton));
        assertEq(privateRegistryClone.owners(), 1);
        assertTrue(privateRegistryClone.isOwner(alice));
    }

    function test_InitializeRegistry_MultipleOwners_CountsEachOwner() public {
        address bob = makeAddr("bob");
        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = bob;

        _changePrank(multisig);
        privateRegistryClone = BaseRegistry(singleton.initializeRegistry(PRIVATE_NAMESPACE, owners));
        _stopPrank();

        assertEq(privateRegistryClone.owners(), 2);
        assertTrue(privateRegistryClone.isOwner(alice));
        assertTrue(privateRegistryClone.isOwner(bob));
    }

    function test_InitializeRegistry_SkipsZeroAddressOwner() public {
        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = address(0);

        _changePrank(multisig);
        address clone = singleton.initializeRegistry(PRIVATE_NAMESPACE, owners);
        _stopPrank();

        assertEq(BaseRegistry(clone).owners(), 1);
    }

    function test_ReInitializeRegistry_OverwritesExistingPointer() public init {
        address oldClone = address(privateRegistryClone);
        bytes4 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));

        address bob = makeAddr("bob");
        address[] memory newOwners = new address[](1);
        newOwners[0] = bob;

        _changePrank(multisig);
        address newClone = singleton.reInitializeRegistry(PRIVATE_NAMESPACE, newOwners);
        _stopPrank();

        assertTrue(newClone != oldClone);
        assertEq(singleton.registry(nsKey), newClone);

        // The old clone is orphaned (no longer referenced by the Singleton), but
        // its own state is untouched — alice is still an owner over there.
        assertTrue(privateRegistryClone.isOwner(alice));
        assertFalse(BaseRegistry(newClone).isOwner(alice));
        assertTrue(BaseRegistry(newClone).isOwner(bob));
    }

    function test_Link_PublicRegistry_AnyoneCanLink() public {
        // @salva has 0 owners, so _verifyOwnership skips the ownership check
        // entirely — literally anyone can link into it.
        bytes4 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked("alice"));

        _changePrank(makeAddr("randomCaller"));
        bool ok = singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        _stopPrank();

        assertTrue(ok);
        assertEq(singleton.resolve(nameHash, nsKey), SAMPLE_LINK_DATA);
    }

    function test_Link_PrivateRegistry_OnlyOwnerCanLink() public init {
        bytes4 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_1));

        _changePrank(alice);
        bool ok = singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        _stopPrank();

        assertTrue(ok);
        assertEq(singleton.resolve(nameHash, nsKey), SAMPLE_LINK_DATA);
    }

    function test_Revert_Link_PrivateRegistry_NonOwnerCannotLink() public init {
        bytes4 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_2));

        _changePrank(makeAddr("notAlice"));
        vm.expectRevert(Errors.Singleton__NotAllowed.selector);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        _stopPrank();
    }

    function test_Unlink_PrivateRegistry_OwnerCanUnlink() public init {
        bytes4 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_1));

        _changePrank(alice);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        bool ok = singleton.unlink(nameHash, nsKey);
        _stopPrank();

        assertTrue(ok);
        assertEq(singleton.resolve(nameHash, nsKey), bytes32(0));
    }

    function test_ResolveAddr_ReturnsAddress() public {
        bytes4 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);

        assertEq(
            singleton.resolveAddr(nameHash, nsKey), address(uint160(uint256(SAMPLE_LINK_DATA)))
        );
    }

    function test_Revert_Link_UnregisteredNamespace() public {
        bytes4 nsKey = singleton.key(bytes("@doesnotexist"));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_2));

        vm.expectRevert(Errors.Singleton__NspaceNotRegistered.selector);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
    }

    function test_Resolve_ReturnsZeroForUnregisteredNamespace() public view {
        // Unlike `link`, `resolve` doesn't revert for an unregistered namespace —
        // `_resolve` just returns bytes32(0) on a missed registry lookup.
        bytes4 nsKey = singleton.key(bytes("@doesnotexist"));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));
        assertEq(singleton.resolve(nameHash, nsKey), bytes32(0));
    }

    function test_Revert_Link_NameAlreadyTaken() public {
        bytes4 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));

        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);

        vm.expectRevert(abi.encodeWithSignature("BaseRegistry__NameTaken()"));
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
    }

    function test_Registry_ReturnsCorrectAddressForKey() public view {
        bytes4 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        assertEq(singleton.registry(nsKey), address(publicRegistryClone));
    }

    function test_Key_IsDeterministicHashOfNamespaceBytes() public view {
        bytes4 expected = bytes4(keccak256(bytes(PUBLIC_NAMESPACE)));
        assertEq(singleton.key(bytes(PUBLIC_NAMESPACE)), expected);
    }
}
