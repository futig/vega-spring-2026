// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CounterV1} from "../src/CounterV1.sol";

contract RollbackScript is Script {
    function run() external {
        uint256 deployerKey  = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        uint256 rollbackIdx  = vm.envUint("ROLLBACK_INDEX");

        vm.startBroadcast(deployerKey);
        CounterV1(proxyAddress).rollbackTo(rollbackIdx);
        vm.stopBroadcast();

        console.log("Rolled back to index:", rollbackIdx);
        console.log("version:", CounterV1(proxyAddress).version());
        console.log("currentVersionIndex:", CounterV1(proxyAddress).currentVersionIndex());
    }
}
