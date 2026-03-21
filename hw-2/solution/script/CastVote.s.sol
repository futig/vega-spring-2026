// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract CastVoteScript is Script {
    function run() external {
        uint256 privateKey = vm.envOr("STAKE_KEY", vm.envUint("PRIVATE_KEY"));
        address voter      = vm.addr(privateKey);

        VegaVoting vegaVoting = VegaVoting(vm.envAddress("VEGA_VOTING_ADDRESS"));
        bytes32    voteId     = vm.envBytes32("VOTE_ID");
        bool       support    = vm.envBool("VOTE_SUPPORT");

        console.log("Voter: %s  VP: %s", voter, vegaVoting.votingPowerOf(voter));

        vm.startBroadcast(privateKey);
        vegaVoting.castVote(voteId, support);
        vm.stopBroadcast();

        VegaVoting.Voting memory v = vegaVoting.getVoting(voteId);
        console.log("Yes: %s  No: %s  Finalized: %s", v.yesVotes, v.noVotes, v.finalized);
    }
}
