// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { IBaseRegistry } from "../src/interfaces/IBaseRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Test } from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    BaseRegistry public baseRegistryImpl;
    Singleton public singleton;
    BaseRegistry public publicRegistryClone;
    BaseRegistry public privateRegistryClone;

    address public multisig = makeAddr("multisig");
    address public alice = makeAddr("alice");

    string public constant PUBLIC_NAMESPACE = "@salva";
    string public constant PRIVATE_NAMESPACE = "@alice";
    bytes public constant ALICE_PRIVATE_NAME_1 = bytes("pay.usdc");
    bytes public constant ALICE_PRIVATE_NAME_2 = bytes("pay.eth.base");
    bytes public constant ALICE_PUBLIC_NAME_1 = bytes("alice");
    bytes public constant ALICE_PUBLIC_NAME_2 = bytes("pay.alice");
    bytes32 public constant SAMPLE_LINK_DATA =
        bytes32(uint256(uint160(0x1234567890123456789012345678901234567890)));

    function setUp() public {
        baseRegistryImpl = new BaseRegistry();
        singleton = new Singleton();

        bytes memory initData = abi.encodeWithSelector(Singleton.initialize.selector, multisig);

        ERC1967Proxy proxy = new ERC1967Proxy(address(singleton), initData);
        singleton = Singleton(address(proxy));

        address[] memory owners = new address[](0);

        _changePrank(multisig);
        singleton.setBaseRegistryImpl(address(baseRegistryImpl));
        publicRegistryClone = BaseRegistry(singleton.initializeRegistry(PUBLIC_NAMESPACE, owners));
        _stopPrank();
    }

    modifier init() {
        address[] memory owners = new address[](1);
        owners[0] = alice;
        _changePrank(multisig);
        privateRegistryClone = BaseRegistry(singleton.initializeRegistry(PRIVATE_NAMESPACE, owners));
        _stopPrank();
        _;
    }

    function _changePrank(address newPrank) internal {
        vm.stopPrank();
        vm.startPrank(newPrank);
    }

    function _stopPrank() internal {
        vm.stopPrank();
    }
}
