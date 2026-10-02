// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { Addresses } from "./Addresses.s.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeploySNS is Script, Addresses {
    string[] internal _defaultNamespaces = ["@sant", "@ngns"];

    function run()
        external
        returns (address proxyAddress, address implAddress, address baseRegistryImplAddress)
    {
        address multisig = _multisig();
        console.log("--- Starting SNS Deployment ---");
        console.log("Multisig Admin:", multisig);

        vm.startBroadcast();

        // 1. Deploy Implementation Contracts
        baseRegistryImplAddress = address(new BaseRegistry());
        implAddress = address(new Singleton());
        console.log("BaseRegistry Impl:", baseRegistryImplAddress);
        console.log("Singleton Impl:", implAddress);

        // 2. Deploy ERC1967 Proxy
        bytes memory initData = abi.encodeWithSelector(Singleton.initialize.selector, multisig);
        proxyAddress = address(new ERC1967Proxy(implAddress, initData));
        Singleton singleton = Singleton(proxyAddress);
        console.log("Singleton Proxy:", proxyAddress);

        // 3. Bypass Quorum
        _executeMultisigSetImpl(multisig, proxyAddress, baseRegistryImplAddress);

        // 4. Verify BaseRegistry Implementation
        assert(singleton.BaseRegistryImpl() == baseRegistryImplAddress);
        console.log("BaseRegistry Implementation verified on Singleton");

        // 5. Bootstrap Default Public Namespaces
        _executeInitRegistries(address(singleton), multisig);
        vm.stopBroadcast();
        console.log("--- SNS Deployment Complete ---");
        // =============================BASE TESTNET===================================
        // Singleton Proxy: 0xdc9711f3E85c11f35735AAE148B969e6cE5F3b9D
        // Registry Address For  @sant :  0x06dE98475D187ee3EF086eE6684520f581BEB5C5
        // Registry Address For  @ngns  :  0x0252e104F207013DEe89745291B4aB8E642a2ac2
    }

    function _executeInitRegistries(address target, address multisig) internal {
        address[] memory Owners = new address[](4);
        Owners[0] = multisig;
        Owners[1] = address(0x17cb8Db361b37AE05137bdE86e472D8d9EDCF7c0);
        Owners[2] = address(0x708657DA3e4eFFa7334779C9A1E759DC38A5BF94);
        Owners[3] = address(0xfD5A9828bac27495FAb7F6174b3de386E0554187);

        for (uint256 i = 0; i < _defaultNamespaces.length; i++) {
            string memory ns = _defaultNamespaces[i];
            (bool ok, bytes memory data) = multisig.call(abi.encodeWithSignature("nonce()"));
            require(ok, "Nonce call failed");
            uint256 nonce = abi.decode(data, (uint256));

            bytes memory initRegistryData =
                abi.encodeWithSignature("initializeRegistry(string,address[])", ns, Owners);
            // Propose
            (ok, data) = multisig.call(
                abi.encodeWithSignature(
                    "propose(address,uint256,bytes)", target, 0, initRegistryData
                )
            );
            require(ok && data.length >= 0x20, "Propose failed");
            bytes32 pHash = abi.decode(data, (bytes32));

            // Approve
            (ok,) = multisig.call(abi.encodeWithSignature("approve(bytes32)", pHash));
            require(ok, "Approve failed");

            // Execute
            (ok, data) = multisig.call(
                abi.encodeWithSignature(
                    "execute(address,uint256,bytes,uint256)", target, 0, initRegistryData, nonce
                )
            );
            require(ok, "Execute failed");
            address registry;
            assembly {
                registry := mload(add(data, 0x60))
            }
            console.log("Initialized Public Namespace For ", ns);
            console.log("Registry Address For ", _defaultNamespaces[i], ": ", registry);
        }
    }

    function _executeMultisigSetImpl(address multisig, address target, address impl) internal {
        // Fetch current nonce
        (bool ok, bytes memory data) = multisig.call(abi.encodeWithSignature("nonce()"));
        require(ok, "Nonce call failed");
        uint256 nonce = abi.decode(data, (uint256));

        bytes memory setImplData = abi.encodeWithSignature("setBaseRegistryImpl(address)", impl);

        // Propose
        (ok, data) = multisig.call(
            abi.encodeWithSignature("propose(address,uint256,bytes)", target, 0, setImplData)
        );
        require(ok && data.length >= 0x20, "Propose failed");
        bytes32 pHash = abi.decode(data, (bytes32));

        // Approve
        (ok,) = multisig.call(abi.encodeWithSignature("approve(bytes32)", pHash));
        require(ok, "Approve failed");

        // Execute
        (ok,) = multisig.call(
            abi.encodeWithSignature(
                "execute(address,uint256,bytes,uint256)", target, 0, setImplData, nonce
            )
        );
        require(ok, "Execute failed");
    }
}
