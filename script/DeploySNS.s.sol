// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeploySNS is Script {
    string[] internal _defaultPublicNamespaces = ["@salva", "@base", "@ngns"];

    function run()
        external
        returns (address proxyAddress, address implAddress, address baseRegistryImplAddress)
    {
        address multisig = address(0x7Fe2bB5D44bFE124A7eDbE507035246e6327CB3A);
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
        address[] memory publicOwners = new address[](0);
        for (uint256 i = 0; i < _defaultPublicNamespaces.length; i++) {
            string memory ns = _defaultPublicNamespaces[i];
            address clone = singleton.initializeRegistry(ns, publicOwners);
            console.log("Initialized Public Namespace:", ns);
            console.log("  -> Key:", vm.toString(singleton.key(bytes(ns))));
            console.log("  -> Registry Clone:", clone);
        }

        vm.stopBroadcast();
        console.log("--- SNS Deployment Complete ---");
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
