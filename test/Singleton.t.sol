// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Errors } from "../src/utils/Errors.sol";
import { BaseTest } from "./BaseTest.t.sol";
import { console } from "forge-std/console.sol";

contract Singleton is BaseTest {
    function test_InitializeRegistry_Success() public view {
        assertEq(publicRegistryClone.namespace(), PUBLIC_NAMESPACE);
        assertEq(publicRegistryClone.singleton(), address(singleton));
        assertEq(publicRegistryClone.getOwners()[0], multisig);
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
        owners[0] = multisig;
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
        owners[0] = multisig;
        _changePrank(multisig);
        vm.expectRevert(Errors.Singleton__DoubleInitialization.selector);
        singleton.initializeRegistry(PUBLIC_NAMESPACE, owners);
        _stopPrank();
    }

    function test_InitializeRegistry_PrivateNamespace_Success() public init {
        assertEq(privateRegistryClone.namespace(), PRIVATE_NAMESPACE);
        assertEq(privateRegistryClone.singleton(), address(singleton));
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

        address[] memory owner = privateRegistryClone.getOwners();
        assertEq(owner[0], alice);
        assertEq(owner[1], bob);
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

        address[] memory owner = BaseRegistry(clone).getOwners();
        assertEq(owner.length, 1);
    }

    function test_ReInitializeRegistry_OverwritesExistingPointer() public init {
        address oldClone = address(privateRegistryClone);
        bytes32 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));

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

    function test_Link_PrivateRegistry_OnlyOwnerCanLink() public init {
        bytes32 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_1));

        _changePrank(alice);
        bool ok = singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        _stopPrank();

        assertTrue(ok);
        assertEq(singleton.resolve(nameHash, nsKey), SAMPLE_LINK_DATA);
    }

    function test_Revert_Link_PrivateRegistry_NonOwnerCannotLink() public init {
        bytes32 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_2));

        _changePrank(makeAddr("notAlice"));
        vm.expectRevert(Errors.Singleton__NotAllowed.selector);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        _stopPrank();
    }

    function test_Unlink_PrivateRegistry_OwnerCanUnlink() public init {
        bytes32 nsKey = singleton.key(bytes(PRIVATE_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PRIVATE_NAME_1));

        _changePrank(alice);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
        bool ok = singleton.unlink(nameHash, nsKey);
        _stopPrank();

        assertTrue(ok);
        assertEq(singleton.resolve(nameHash, nsKey), bytes32(0));
    }

    function test_ResolveAddr_ReturnsAddress() public {
        _changePrank(multisig);
        bytes32 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);

        assertEq(
            singleton.resolveAddr(nameHash, nsKey), address(uint160(uint256(SAMPLE_LINK_DATA)))
        );
    }

    function test_Revert_Link_UnregisteredNamespace() public {
        bytes32 nsKey = singleton.key(bytes("@doesnotexist"));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_2));

        vm.expectRevert(Errors.Singleton__NspaceNotRegistered.selector);
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
    }

    function test_Resolve_ReturnsZeroForUnregisteredNamespace() public view {
        // Unlike `link`, `resolve` doesn't revert for an unregistered namespace —
        // `_resolve` just returns bytes32(0) on a missed registry lookup.
        bytes32 nsKey = singleton.key(bytes("@doesnotexist"));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));
        assertEq(singleton.resolve(nameHash, nsKey), bytes32(0));
    }

    function test_Revert_Link_NameAlreadyTaken() public {
        _changePrank(multisig);
        bytes32 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        bytes32 nameHash = keccak256(abi.encodePacked(ALICE_PUBLIC_NAME_1));

        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);

        vm.expectRevert(abi.encodeWithSignature("BaseRegistry__NameTaken()"));
        singleton.link(nameHash, nsKey, SAMPLE_LINK_DATA);
    }

    function test_Registry_ReturnsCorrectAddressForKey() public view {
        bytes32 nsKey = singleton.key(bytes(PUBLIC_NAMESPACE));
        assertEq(singleton.registry(nsKey), address(publicRegistryClone));
    }

    function test_Key_IsDeterministicHashOfNamespaceBytes() public view {
        bytes32 expected = keccak256(bytes(PUBLIC_NAMESPACE));
        assertEq(singleton.key(bytes(PUBLIC_NAMESPACE)), expected);
    }

    function test_encode() public pure {
        address owners = address(0x17cb8Db361b37AE05137bdE86e472D8d9EDCF7c0);
        console.logBytes(abi.encodeWithSignature("updateValidator(address,bool)", owners, true));
    }
}
