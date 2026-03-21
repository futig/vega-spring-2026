// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VVToken}    from "../src/VVToken.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract StakeScript is Script {
    uint256 constant STAKE_AMOUNT   = 100 * 1e18;
    uint256 constant STAKE_DURATION = 2 * 365 days;

    function run() external {
        uint256 privateKey = vm.envOr("STAKE_KEY", vm.envUint("PRIVATE_KEY"));
        address caller     = vm.addr(privateKey);

        VVToken    vvToken    = VVToken(vm.envAddress("VV_TOKEN_ADDRESS"));
        VegaVoting vegaVoting = VegaVoting(vm.envAddress("VEGA_VOTING_ADDRESS"));

        vm.startBroadcast(privateKey);

        vvToken.approve(address(vegaVoting), STAKE_AMOUNT);
        vegaVoting.stake(STAKE_AMOUNT, STAKE_DURATION);

        vm.stopBroadcast();

        console.log("Staked 100 VV for 2 years from %s", caller);
        console.log("Voting power: %s", vegaVoting.votingPowerOf(caller));
    }
}
