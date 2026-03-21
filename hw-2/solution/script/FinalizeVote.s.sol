// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract FinalizeVoteScript is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        VegaVoting vegaVoting = VegaVoting(vm.envAddress("VEGA_VOTING_ADDRESS"));
        bytes32    voteId     = vm.envBytes32("VOTE_ID");

        vm.startBroadcast(privateKey);
        vegaVoting.finalizeVote(voteId);
        vm.stopBroadcast();

        VegaVoting.Voting memory v = vegaVoting.getVoting(voteId);
        console.log("Passed: %s  Yes: %s  No: %s", v.passed, v.yesVotes, v.noVotes);
    }
}
