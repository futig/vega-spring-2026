// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VVToken}    from "../src/VVToken.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        VVToken vvToken = new VVToken(deployer);
        console.log("VVToken    deployed:", address(vvToken));

        VegaVoting vegaVoting = new VegaVoting(address(vvToken), deployer);
        console.log("VegaVoting deployed:", address(vegaVoting));

        vm.stopBroadcast();

        console.log("VV_TOKEN_ADDRESS=%s", address(vvToken));
        console.log("VEGA_VOTING_ADDRESS=%s", address(vegaVoting));
    }
}
