SHELL := /bin/bash
BLOCKSCOUT_URL := https://eth-sepolia.blockscout.com/api/

.PHONY: install build test test-v deploy-sepolia setup-vote stake-sepolia vote-sepolia verify-sepolia

include .env
export

install:
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.0
	forge install foundry-rs/forge-std

build:
	forge build

test:
	forge test

test-v:
	forge test -vvv

deploy-sepolia:
	forge script script/Deploy.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

verify-sepolia:
	forge verify-contract $(VV_TOKEN_ADDRESS) src/VVToken.sol:VVToken \
		--chain 11155111 \
		--constructor-args $(shell cast abi-encode "constructor(address)" $(shell cast wallet address --private-key $(PRIVATE_KEY))) \
		--verifier blockscout \
		--verifier-url $(BLOCKSCOUT_URL)
	forge verify-contract $(VEGA_VOTING_ADDRESS) src/VegaVoting.sol:VegaVoting \
		--chain 11155111 \
		--constructor-args $(shell cast abi-encode "constructor(address,address)" $(VV_TOKEN_ADDRESS) $(shell cast wallet address --private-key $(PRIVATE_KEY))) \
		--verifier blockscout \
		--verifier-url $(BLOCKSCOUT_URL)

setup-vote:
	forge script script/SetupVote.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

stake-sepolia:
	forge script script/Stake.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

vote-sepolia:
	forge script script/CastVote.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv

finalize-sepolia:
	forge script script/FinalizeVote.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		-vvvv
