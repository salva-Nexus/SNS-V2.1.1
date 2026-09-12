// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Addresses
 * @notice Abstract contract mapping EVM chain IDs to network-specific deployment addresses
 */
abstract contract Addresses {
    // ------------------------------------------------------------------------
    // Chain ID Constants
    // ------------------------------------------------------------------------
    uint256 internal constant BASE_MAINNET = 8453;
    uint256 internal constant BASE_SEPOLIA = 84532;

    // ------------------------------------------------------------------------
    // Internal Routing Functions
    // ------------------------------------------------------------------------

    function _multisig() internal view returns (address) {
        return block.chainid == BASE_SEPOLIA
            ? address(0x7Fe2bB5D44bFE124A7eDbE507035246e6327CB3A)
            : address(0x1234);
    }

    function _singleton() internal view returns (address) {
        return block.chainid == BASE_SEPOLIA
            ? address(0xC9Eaa3DD7c87bE3269677F281C59A063201D4e09)
            : address(0x1234);
    }
}
