// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VVToken}    from "../src/VVToken.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract VegaVotingTest is Test {
    VVToken    token;
    VegaVoting voting;

    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    uint256 constant YEAR            = 365 days;
    uint256 constant INITIAL_TOKENS  = 10_000 * 1e18;

    // ─── Setup ────────────────────────────────────────────────────────────────

    function setUp() public {
        vm.startPrank(admin);
        token  = new VVToken(admin);
        voting = new VegaVoting(address(token), admin);

        token.transfer(alice, INITIAL_TOKENS);
        token.transfer(bob,   INITIAL_TOKENS);
        vm.stopPrank();

        vm.prank(alice);
        token.approve(address(voting), type(uint256).max);

        vm.prank(bob);
        token.approve(address(voting), type(uint256).max);
    }

    // ─── Staking: valid cases ─────────────────────────────────────────────────

    function test_StakeMinDuration() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);

        VegaVoting.Stake[] memory stakes = voting.getUserStakes(alice);
        assertEq(stakes.length, 1);
        assertEq(stakes[0].amount, 100 * 1e18);
        assertEq(stakes[0].expiry, block.timestamp + YEAR);
    }

    function test_StakeMaxDuration() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, 4 * YEAR);

        assertEq(voting.getUserStakes(alice).length, 1);
    }

    function test_StakeTransfersTokensToContract() public {
        uint256 before = token.balanceOf(alice);
        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        assertEq(token.balanceOf(alice), before - 100 * 1e18);
        assertEq(token.balanceOf(address(voting)), 100 * 1e18);
    }

    function test_StakeMultipleTimes() public {
        vm.startPrank(alice);
        voting.stake(100 * 1e18, YEAR);
        voting.stake(200 * 1e18, 2 * YEAR);
        voting.stake(300 * 1e18, 3 * YEAR);
        vm.stopPrank();

        assertEq(voting.getUserStakes(alice).length, 3);
    }

    // ─── Staking: reverts ─────────────────────────────────────────────────────

    function test_StakeZeroAmount_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("VegaVoting: amount must be positive");
        voting.stake(0, YEAR);
    }

    function test_StakeBelowMinDuration_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("VegaVoting: duration must be in [1, 4] years");
        voting.stake(100 * 1e18, YEAR - 1);
    }

    function test_StakeAboveMaxDuration_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("VegaVoting: duration must be in [1, 4] years");
        voting.stake(100 * 1e18, 4 * YEAR + 1);
    }

    function test_StakeWhenPaused_Reverts() public {
        vm.prank(admin);
        voting.pause();

        vm.prank(alice);
        vm.expectRevert();
        voting.stake(100 * 1e18, YEAR);
    }

    // ─── Unstaking ───────────────────────────────────────────────────────────

    function test_UnstakeAfterExpiry() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);

        vm.warp(block.timestamp + YEAR);

        uint256 before = token.balanceOf(alice);
        vm.prank(alice);
        voting.unstake(0);

        assertEq(token.balanceOf(alice), before + 100 * 1e18);
        assertEq(voting.getUserStakes(alice)[0].amount, 0);
    }

    function test_UnstakeBeforeExpiry_Reverts() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);

        vm.prank(alice);
        vm.expectRevert("VegaVoting: stake not yet expired");
        voting.unstake(0);
    }

    function test_UnstakeAlreadyWithdrawn_Reverts() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);

        vm.warp(block.timestamp + YEAR);
        vm.prank(alice);
        voting.unstake(0);

        vm.prank(alice);
        vm.expectRevert("VegaVoting: already withdrawn");
        voting.unstake(0);
    }

    function test_UnstakeInvalidIndex_Reverts() public {
        vm.prank(alice);
        vm.expectRevert("VegaVoting: invalid stake index");
        voting.unstake(0);
    }

    // ─── Voting power ────────────────────────────────────────────────────────

    /// @dev VP = (2 years)² × 100 VV / (1 year)² = 4 × 100e18 = 400e18
    function test_VotingPowerAtStakeStart() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        assertEq(voting.votingPowerOf(alice), 400 * 1e18);
    }

    /// @dev After 1 year: remaining = 1 year → VP = 1² × 100e18 = 100e18
    function test_VotingPowerDecaysOverTime() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        assertEq(voting.votingPowerOf(alice), 400 * 1e18);

        vm.warp(block.timestamp + YEAR);
        assertEq(voting.votingPowerOf(alice), 100 * 1e18);
    }

    function test_VotingPowerZeroAfterExpiry() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);

        vm.warp(block.timestamp + YEAR);
        assertEq(voting.votingPowerOf(alice), 0);
    }

    function test_VotingPowerNoStakes() public view {
        assertEq(voting.votingPowerOf(alice), 0);
    }

    /// @dev 100 VV for 2 years + 50 VV for 1 year → 400e18 + 50e18 = 450e18
    function test_VotingPowerSumsMultipleStakes() public {
        vm.startPrank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);
        voting.stake(50 * 1e18,  1 * YEAR);
        vm.stopPrank();

        assertEq(voting.votingPowerOf(alice), 450 * 1e18);
    }

    /// @dev Expired stake contributes 0; only active stake counts.
    function test_VotingPowerIgnoresExpiredStakes() public {
        vm.startPrank(alice);
        voting.stake(100 * 1e18, YEAR);       // expires after 1 year
        voting.stake(50 * 1e18,  2 * YEAR);   // expires after 2 years
        vm.stopPrank();

        vm.warp(block.timestamp + YEAR);

        // First stake expired; second has 1 year left → VP = 1² × 50e18 = 50e18
        assertEq(voting.votingPowerOf(alice), 50 * 1e18);
    }

    // ─── Vote creation ────────────────────────────────────────────────────────

    function test_AdminCanCreateVote() public {
        bytes32 id       = keccak256("proposal-1");
        uint256 deadline = block.timestamp + 7 days;
        uint256 threshold = 1000 * 1e18;

        vm.prank(admin);
        voting.createVote(id, deadline, threshold, "Should we upgrade?");

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertEq(v.id, id);
        assertEq(v.deadline, deadline);
        assertEq(v.votingPowerThreshold, threshold);
        assertEq(v.description, "Should we upgrade?");
        assertFalse(v.finalized);
    }

    function test_VotingCountIncreases() public {
        assertEq(voting.getVotingCount(), 0);

        vm.prank(admin);
        voting.createVote(keccak256("v1"), block.timestamp + 1 days, 1e18, "Q1");

        assertEq(voting.getVotingCount(), 1);
    }

    function test_CreateVoteNonAdmin_Reverts() public {
        vm.prank(alice);
        vm.expectRevert();
        voting.createVote(keccak256("v1"), block.timestamp + 7 days, 1e18, "Q");
    }

    function test_CreateVoteDuplicateId_Reverts() public {
        bytes32 id = keccak256("v1");
        vm.prank(admin);
        voting.createVote(id, block.timestamp + 7 days, 1e18, "Q");

        vm.prank(admin);
        vm.expectRevert("VegaVoting: vote ID already exists");
        voting.createVote(id, block.timestamp + 14 days, 1e18, "Q2");
    }

    function test_CreateVotePastDeadline_Reverts() public {
        vm.prank(admin);
        vm.expectRevert("VegaVoting: deadline must be in the future");
        voting.createVote(keccak256("v1"), block.timestamp - 1, 1e18, "Q");
    }

    function test_CreateVoteZeroThreshold_Reverts() public {
        vm.prank(admin);
        vm.expectRevert("VegaVoting: threshold must be positive");
        voting.createVote(keccak256("v1"), block.timestamp + 7 days, 0, "Q");
    }

    function test_CreateVoteEmptyDescription_Reverts() public {
        vm.prank(admin);
        vm.expectRevert("VegaVoting: empty description");
        voting.createVote(keccak256("v1"), block.timestamp + 7 days, 1e18, "");
    }

    // ─── Vote casting ─────────────────────────────────────────────────────────

    function test_CastVoteYes() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);  // VP = 400e18

        vm.prank(alice);
        voting.castVote(id, true);

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertEq(v.yesVotes, 400 * 1e18);
        assertEq(v.noVotes, 0);
    }

    function test_CastVoteNo() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.prank(alice);
        voting.castVote(id, false);

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertEq(v.noVotes, 400 * 1e18);
        assertEq(v.yesVotes, 0);
    }

    function test_CannotVoteTwice_Reverts() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.startPrank(alice);
        voting.castVote(id, true);
        vm.expectRevert("VegaVoting: already voted");
        voting.castVote(id, false);
        vm.stopPrank();
    }

    function test_CannotVoteAfterDeadline_Reverts() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.warp(block.timestamp + 8 days);   // past 7-day deadline

        vm.prank(alice);
        vm.expectRevert("VegaVoting: voting period ended");
        voting.castVote(id, true);
    }

    function test_CannotVoteWithNoStake_Reverts() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        vm.expectRevert("VegaVoting: no voting power");
        voting.castVote(id, true);
    }

    function test_CannotVoteOnNonexistentVote_Reverts() public {
        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.prank(alice);
        vm.expectRevert("VegaVoting: vote does not exist");
        voting.castVote(keccak256("nonexistent"), true);
    }

    function test_TwoVotersAccumulate() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);  // VP_alice = 400e18

        vm.prank(bob);
        voting.stake(50 * 1e18, 1 * YEAR);   // VP_bob = 50e18

        vm.prank(alice);
        voting.castVote(id, true);

        vm.prank(bob);
        voting.castVote(id, false);

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertEq(v.yesVotes, 400 * 1e18);
        assertEq(v.noVotes,  50  * 1e18);
    }

    // ─── Finalization ─────────────────────────────────────────────────────────

    function test_FinalizeByDeadline() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);
        vm.prank(alice);
        voting.castVote(id, true);

        vm.warp(block.timestamp + 8 days);   // past deadline
        voting.finalizeVote(id);

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertTrue(v.finalized);
        assertFalse(v.passed);   // yesVotes < threshold
    }

    function test_FinalizeEarlyWhenThresholdMet() public {
        // Threshold = 100e18; VP = 400e18 → passes immediately
        bytes32 id = _createVote(100 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.prank(alice);
        voting.castVote(id, true);   // triggers early finalization

        VegaVoting.Voting memory v = voting.getVoting(id);
        assertTrue(v.finalized);
        assertTrue(v.passed);
    }

    function test_FinalizeBeforeDeadline_Reverts() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.expectRevert("VegaVoting: voting period not ended");
        voting.finalizeVote(id);
    }

    function test_FinalizeTwice_Reverts() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.warp(block.timestamp + 8 days);
        voting.finalizeVote(id);

        vm.expectRevert("VegaVoting: vote already finalized");
        voting.finalizeVote(id);
    }

    function test_AnyoneCanFinalizeAfterDeadline() public {
        bytes32 id = _createVote(10_000 * 1e18);

        vm.warp(block.timestamp + 8 days);

        vm.prank(alice);   // alice is not admin
        voting.finalizeVote(id);

        assertTrue(voting.getVoting(id).finalized);
    }

    function test_CannotVoteOnFinalizedVote_Reverts() public {
        bytes32 id = _createVote(100 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);
        vm.prank(alice);
        voting.castVote(id, true);   // triggers finalization

        vm.prank(bob);
        voting.stake(50 * 1e18, 2 * YEAR);
        vm.prank(bob);
        vm.expectRevert("VegaVoting: vote already finalized");
        voting.castVote(id, false);
    }

    // ─── NFT result ───────────────────────────────────────────────────────────

    function test_NFTMintedToAdminOnFinalization() public {
        bytes32 id = _createVote(100 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);
        vm.prank(alice);
        voting.castVote(id, true);   // early finalization

        assertEq(voting.ownerOf(0), admin);
    }

    function test_NFTResultDataCorrect() public {
        bytes32 id = _createVote(100 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);
        vm.prank(alice);
        voting.castVote(id, true);

        VegaVoting.VoteResult memory r = voting.getVoteResult(0);
        assertEq(r.voteId,   id);
        assertEq(r.yesVotes, 400 * 1e18);
        assertEq(r.noVotes,  0);
        assertTrue(r.passed);
    }

    function test_MultipleVotesProduceMultipleNFTs() public {
        bytes32 id1 = keccak256("v1");
        bytes32 id2 = keccak256("v2");

        vm.startPrank(admin);
        voting.createVote(id1, block.timestamp + 7 days, 100 * 1e18, "Vote 1");
        voting.createVote(id2, block.timestamp + 7 days, 100 * 1e18, "Vote 2");
        vm.stopPrank();

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        // Vote1 early-finalizes
        vm.prank(alice);
        voting.castVote(id1, true);

        // Vote2 finalizes by deadline
        vm.warp(block.timestamp + 8 days);
        voting.finalizeVote(id2);

        assertEq(voting.ownerOf(0), admin);
        assertEq(voting.ownerOf(1), admin);
        assertEq(voting.getVoteResult(0).voteId, id1);
        assertEq(voting.getVoteResult(1).voteId, id2);
    }

    // ─── Emergency controls ───────────────────────────────────────────────────

    function test_PauseBlocksStaking() public {
        vm.prank(admin);
        voting.pause();

        vm.prank(alice);
        vm.expectRevert();
        voting.stake(100 * 1e18, YEAR);
    }

    function test_PauseBlocksVoting() public {
        bytes32 id = _createVoteUnpaused(10_000 * 1e18);

        vm.prank(alice);
        voting.stake(100 * 1e18, 2 * YEAR);

        vm.prank(admin);
        voting.pause();

        vm.prank(alice);
        vm.expectRevert();
        voting.castVote(id, true);
    }

    function test_UnpauseRestoresStaking() public {
        vm.prank(admin);
        voting.pause();

        vm.prank(admin);
        voting.unpause();

        vm.prank(alice);
        voting.stake(100 * 1e18, YEAR);   // should succeed

        assertEq(voting.getUserStakes(alice).length, 1);
    }

    function test_PauseOnlyOwner_Reverts() public {
        vm.prank(alice);
        vm.expectRevert();
        voting.pause();
    }

    function test_UnpauseOnlyOwner_Reverts() public {
        vm.prank(admin);
        voting.pause();

        vm.prank(alice);
        vm.expectRevert();
        voting.unpause();
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    function _createVote(uint256 threshold) internal returns (bytes32 id) {
        id = keccak256(abi.encodePacked("vote", threshold, block.timestamp));
        vm.prank(admin);
        voting.createVote(id, block.timestamp + 7 days, threshold, "Test proposal");
    }

    /// @dev Same as _createVote but can be called after the contract is paused
    ///      (we create before pausing in setup).
    function _createVoteUnpaused(uint256 threshold) internal returns (bytes32 id) {
        id = keccak256(abi.encodePacked("voteU", threshold, block.timestamp));
        vm.prank(admin);
        voting.createVote(id, block.timestamp + 7 days, threshold, "Test proposal paused");
    }
}
