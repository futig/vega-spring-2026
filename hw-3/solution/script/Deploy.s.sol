// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {CounterV1}   from "../src/CounterV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        CounterV1    impl  = new CounterV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(CounterV1.initialize, (deployer))
        );

        vm.stopBroadcast();

        console.log("CounterV1 impl:", address(impl));
        console.log("Proxy:         ", address(proxy));
        console.log("PROXY_ADDRESS=%s", address(proxy));
    }
}
