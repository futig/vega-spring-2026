SHELL := /bin/bash
BLOCKSCOUT_URL := https://eth-sepolia.blockscout.com/api/

include .env
export

.PHONY: install build test test-v inspect deploy-sepolia upgrade-sepolia rollback-sepolia verify-sepolia

install:
	forge install OpenZeppelin/openzeppelin-contracts@v5.0.0
	forge install foundry-rs/forge-std

build:
	forge build

test:
	forge test

test-v:
	forge test -vvv

inspect:
	forge inspect src/CounterV1.sol:CounterV1 storage-layout
	forge inspect src/CounterV2.sol:CounterV2 storage-layout

deploy-sepolia:
	forge script script/Deploy.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast -vvvv

verify-sepolia:
	forge verify-contract $(shell cat broadcast/Deploy.s.sol/11155111/run-latest.json | python3 -c "import sys,json; txs=json.load(sys.stdin)['transactions']; [print(t['contractAddress']) for t in txs if t['contractName']=='CounterV1']") \
		src/CounterV1.sol:CounterV1 \
		--verifier blockscout \
		--verifier-url $(BLOCKSCOUT_URL) \
		--rpc-url $(SEPOLIA_RPC_URL)

upgrade-sepolia:
	forge script script/Upgrade.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast -vvvv

rollback-sepolia:
	forge script script/Rollback.s.sol \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast -vvvv
