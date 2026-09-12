# Load environment variables from .env
include .env

# DEPLOY
DEPLOY-TO-BASE-MAINNET:
	forge script script/DeploySNS.s.sol:DeploySNS --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BASE-TESTNET:
	forge script script/DeploySNS.s.sol:DeploySNS --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BNB-MAINNET:
	forge script script/DeploySNS.s.sol:DeploySNS --rpc-url ${BNB_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

DEPLOY-TO-BNB-TESTNET:
	forge script script/DeploySNS.s.sol:DeploySNS --rpc-url ${BNB_TESTNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}


# UPGRADE
BASE-MAINNET-UPGRAGE:
	forge script script/UpgradeSingleton.s.sol:UpgradeSingleton --rpc-url ${BASE_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

BASE-TESTNET-UPGRAGE:
	forge script script/UpgradeSingleton.s.sol:UpgradeSingleton --rpc-url ${BASE_SEPOLIA_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

BNB-MAINNET-UPGRAGE:
	forge script script/UpgradeSingleton.s.sol:UpgradeSingleton --rpc-url ${BNB_MAINNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}

BNB-TESTNET-UPGRAGE:
	forge script script/UpgradeSingleton.s.sol:UpgradeSingleton --rpc-url ${BNB_TESTNET_RPC_URL} --account mainKey --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}


# VERIFY
VERIFY-BASE-MAINNET: 
	forge verify-contract 0x1234 src/Singleton.sol:Singleton --chain-id 8453 --rpc-url ${BASE_MAINNET_RPC_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} --watch

VERIFY-BASE-TESTNET: 
	forge verify-contract 0x545F1b8218c75c72497e96C06D7D5A4743b0e84f src/Singleton.sol:Singleton --chain-id 84532 --rpc-url ${BASE_SEPOLIA_RPC_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} --watch