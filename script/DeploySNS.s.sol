// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseRegistry } from "../src/BaseRegistry.sol";
import { Singleton } from "../src/Singleton.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";

contract DeploySNS is Script {
    string[] internal _defaultPublicNamespaces = ["@salva", "@base", "@ngns"];
    // Ethereum
    uint256 public constant ETH_MAINNET = 1;
    uint256 public constant ETH_SEPOLIA = 11155111;

    // Base
    uint256 public constant BASE_MAINNET = 8453;
    uint256 public constant BASE_SEPOLIA = 84532;

    // BNB Smart Chain
    uint256 public constant BSC_MAINNET = 56;
    uint256 public constant BSC_TESTNET = 97;

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
        _executeInitPublicRegistries(address(singleton), multisig);
        vm.stopBroadcast();
        console.log("--- SNS Deployment Complete ---");
        // =============================BASE TESTNET===================================
        // Singleton Proxy: 0xC9Eaa3DD7c87bE3269677F281C59A063201D4e09
        // BaseRegistry Impl: 0xB6adD04c76D6e398eBB15CD9B1De052AA442F956
        // Registry Address For  @salva :  0x9b29bdD5B864eC8B7Cd69AC87caB55d10BCcA14D
        // Registry Address For  @base  :  0x60130D8bbE18D2464b6FF1C2680B074f25de0421
        // Registry Address For  @ngns  :  0xa1f9bb9cf82c873a3dF6F8ec14146137949Ea7cF
    }

    function _executeInitPublicRegistries(address target, address multisig) internal {
        address[] memory publicOwners = new address[](0);
        for (uint256 i = 0; i < _defaultPublicNamespaces.length; i++) {
            string memory ns = _defaultPublicNamespaces[i];
            (bool ok, bytes memory data) = multisig.call(abi.encodeWithSignature("nonce()"));
            require(ok, "Nonce call failed");
            uint256 nonce = abi.decode(data, (uint256));

            bytes memory initRegistryData =
                abi.encodeWithSignature("initializeRegistry(string,address[])", ns, publicOwners);
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
            console.log("Registry Address For ", _defaultPublicNamespaces[i], ": ", registry);
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

    function _multisig() internal view returns (address) {
        return block.chainid == BASE_SEPOLIA
            ? address(0x7Fe2bB5D44bFE124A7eDbE507035246e6327CB3A)
            : block.chainid == BASE_MAINNET
                ? address(0x1234)
                : block.chainid == BSC_MAINNET
                    ? address(0x1234)
                    : block.chainid == BSC_TESTNET
                        ? address(0x1234)
                        : block.chainid == ETH_SEPOLIA ? address(0x1234) : address(0x1234);
    }
}
