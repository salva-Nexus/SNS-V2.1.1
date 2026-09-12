// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeploySNS is Script {
    // Default public namespaces to bootstrap on deployment
    string[] internal _defaultPublicNamespaces = ["@salva", "@base", "@ngns"];

    function run()
        external
        returns (address proxyAddress, address implAddress, address baseRegistryImplAddress)
    {
        address multisigBaseTestnet = address(0x7Fe2bB5D44bFE124A7eDbE507035246e6327CB3A);
        console.log("--- Starting SNS Deployment ---");
        console.log("Multisig Admin:", multisigBaseTestnet);

        vm.startBroadcast();

        // 1. Deploy Implementation Contracts
        BaseRegistry baseRegistryImpl = new BaseRegistry();
        baseRegistryImplAddress = address(baseRegistryImpl);
        console.log("BaseRegistry Implementation deployed at:", baseRegistryImplAddress);

        Singleton singletonImpl = new Singleton();
        implAddress = address(singletonImpl);
        console.log("Singleton Implementation deployed at:", implAddress);

        // 2. Deploy ERC1967 Proxy pointing to Singleton
        bytes memory initData =
            abi.encodeWithSelector(Singleton.initialize.selector, multisigBaseTestnet);
        ERC1967Proxy proxy = new ERC1967Proxy(implAddress, initData);
        proxyAddress = address(proxy);
        Singleton singleton = Singleton(proxyAddress);
        console.log("Singleton ERC1967 Proxy deployed at:", proxyAddress);

        // 3. Bypass Quorum via Recovery Multisig Execution
        bytes memory nonceData = abi.encodeWithSignature("nonce()");
        (bool s, bytes memory r) = multisigBaseTestnet.call(nonceData);
        if (!s) revert("Nonce call failed");
        uint256 nonce = abi.decode(r, (uint256));

        bytes memory setImplData =
            abi.encodeWithSignature("setBaseRegistryImpl(address)", baseRegistryImplAddress);
        bytes memory proposeData =
            abi.encodeWithSignature("propose(address,uint256,bytes)", proxyAddress, 0, setImplData);

        (bool s1, bytes memory r1) = multisigBaseTestnet.call(proposeData);
        if (!s1 || r1.length < 0x20) revert("Propose failed");
        bytes32 pHash = abi.decode(r1, (bytes32));

        bytes memory approveData = abi.encodeWithSignature("approve(bytes32)", pHash);
        (bool s2,) = multisigBaseTestnet.call(approveData);
        if (!s2) revert("Approve failed");

        bytes memory executeData = abi.encodeWithSignature(
            "execute(address,uint256,bytes,uint256)", proxyAddress, 0, setImplData, nonce
        );
        (bool s3,) = multisigBaseTestnet.call(executeData);
        if (!s3) revert("Execute failed"); // Fixed revert condition

        // 4. Verify BaseRegistry Implementation setting
        address baseReg = singleton.BaseRegistryImpl();
        assert(baseReg == baseRegistryImplAddress);
        console.log("BaseRegistry Implementation verified on Singleton");

        // 5. Bootstrap Default Public Namespaces (owners length = 0)
        address[] memory publicOwners = new address[](0);

        for (uint256 i = 0; i < _defaultPublicNamespaces.length; i++) {
            string memory ns = _defaultPublicNamespaces[i];
            address clone = singleton.initializeRegistry(ns, publicOwners);
            bytes4 nsKey = singleton.key(bytes(ns));

            console.log("Initialized Public Namespace:", ns);
            console.log("  -> Key:", vm.toString(nsKey));
            console.log("  -> Registry Clone:", clone);
        }

        vm.stopBroadcast();

        console.log("--- SNS Deployment Complete ---");
    }
}
