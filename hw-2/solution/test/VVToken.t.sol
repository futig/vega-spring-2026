// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VVToken} from "../src/VVToken.sol";

contract VVTokenTest is Test {
    VVToken token;

    address owner = makeAddr("owner");
    address user  = makeAddr("user");

    function setUp() public {
        vm.prank(owner);
        token = new VVToken(owner);
    }

    // ─── Deployment ───────────────────────────────────────────────────────────

    function test_Name() public view {
        assertEq(token.name(), "VegaVoting");
    }

    function test_Symbol() public view {
        assertEq(token.symbol(), "VV");
    }

    function test_InitialSupplyMintedToOwner() public view {
        uint256 expected = 1_000_000 * 1e18;
        assertEq(token.totalSupply(), expected);
        assertEq(token.balanceOf(owner), expected);
    }

    // ─── Minting ──────────────────────────────────────────────────────────────

    function test_OwnerCanMint() public {
        vm.prank(owner);
        token.mint(user, 500 * 1e18);

        assertEq(token.balanceOf(user), 500 * 1e18);
        assertEq(token.totalSupply(), 1_000_500 * 1e18);
    }

    function test_MintRevertsForNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 1 * 1e18);
    }

    function test_MintToZeroAddress_Reverts() public {
        vm.prank(owner);
        vm.expectRevert();
        token.mint(address(0), 1 * 1e18);
    }

    // ─── Transfer ────────────────────────────────────────────────────────────

    function test_Transfer() public {
        vm.prank(owner);
        token.transfer(user, 100 * 1e18);

        assertEq(token.balanceOf(user), 100 * 1e18);
        assertEq(token.balanceOf(owner), 999_900 * 1e18);
    }

    // ─── Ownership ───────────────────────────────────────────────────────────

    function test_OwnershipTransfer() public {
        vm.prank(owner);
        token.transferOwnership(user);

        assertEq(token.owner(), user);
    }
}
