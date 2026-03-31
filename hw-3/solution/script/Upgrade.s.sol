// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CounterV1} from "../src/CounterV1.sol";
import {CounterV2} from "../src/CounterV2.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerKey  = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerKey);

        CounterV2 implV2 = new CounterV2();
        CounterV1(proxyAddress).upgradeToAndCall(
            address(implV2),
            abi.encodeCall(CounterV2.initializeV2, (5))
        );

        vm.stopBroadcast();

        console.log("CounterV2 impl:", address(implV2));
        console.log("version:", CounterV1(proxyAddress).version());
        console.log("currentVersionIndex:", CounterV1(proxyAddress).currentVersionIndex());
    }
}
