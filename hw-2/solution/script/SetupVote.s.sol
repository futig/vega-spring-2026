// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {VVToken}    from "../src/VVToken.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract SetupVoteScript is Script {
    function run() external {
        uint256 adminKey = vm.envUint("PRIVATE_KEY");
        address voter2   = vm.envAddress("VOTER2_ADDRESS");

        VVToken    vvToken    = VVToken(vm.envAddress("VV_TOKEN_ADDRESS"));
        VegaVoting vegaVoting = VegaVoting(vm.envAddress("VEGA_VOTING_ADDRESS"));

        vm.startBroadcast(adminKey);

        vvToken.transfer(voter2, 500 * 1e18);

        bytes32 voteId   = keccak256(abi.encodePacked("proposal-1", block.timestamp));
        uint256 deadline = block.timestamp + 7 days;

        vegaVoting.createVote(voteId, deadline, 1_000 * 1e18, "Should the Vega protocol upgrade to v2?");

        vm.stopBroadcast();

        console.log("VOTE_ID=");
        console.logBytes32(voteId);
    }
}
