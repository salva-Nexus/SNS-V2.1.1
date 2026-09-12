// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Singleton } from "../src/Singleton.sol";
import { Addresses } from "./Addresses.s.sol";
import { Script, console2 } from "forge-std/Script.sol";

contract UpgradeSingleton is Script, Addresses {
    function run() external {
        console2.log("==================================================");
        console2.log("SNS Singleton Upgrade Script");
        console2.log("Target Singleton Proxy:", _singleton());
        console2.log("==================================================");

        vm.startBroadcast();
        Singleton singletonImpl = new Singleton();
        console2.log("[+] New Singleton Implementation Deployed at:", address(singletonImpl));

        bytes memory upgradePayload = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)", address(singletonImpl), ""
        );

        // Fetch current nonce
        (bool ok, bytes memory data) = _multisig().call(abi.encodeWithSignature("nonce()"));
        require(ok, "Nonce call failed");
        uint256 nonce = abi.decode(data, (uint256));

        // Propose
        (ok, data) = _multisig()
            .call(
                abi.encodeWithSignature(
                    "propose(address,uint256,bytes)", _singleton(), 0, upgradePayload
                )
            );
        require(ok && data.length >= 0x20, "Propose failed");
        bytes32 pHash = abi.decode(data, (bytes32));

        // Approve
        (ok,) = _multisig().call(abi.encodeWithSignature("approve(bytes32)", pHash));
        require(ok, "Approve failed");

        // Execute
        (ok,) = _multisig()
            .call(
                abi.encodeWithSignature(
                    "execute(address,uint256,bytes,uint256)", _singleton(), 0, upgradePayload, nonce
                )
            );
        require(ok, "Execute failed");

        console2.log("[SUCCESS] Proxy upgraded directly to new implementation!");
        vm.stopBroadcast();
    }
}
