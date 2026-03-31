// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CounterV1} from "../src/CounterV1.sol";
import {CounterV2} from "../src/CounterV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CounterTest is Test {
    address owner = address(1);
    address alice = address(2);

    CounterV1 implV1;
    CounterV2 implV2;
    CounterV1 proxy;
    address proxyAddr;

    function setUp() public {
        implV1 = new CounterV1();
        implV2 = new CounterV2();

        ERC1967Proxy p = new ERC1967Proxy(
            address(implV1),
            abi.encodeCall(CounterV1.initialize, (owner))
        );
        proxyAddr = address(p);
        proxy = CounterV1(proxyAddr);
    }

    function _upgradeToV2() internal {
        vm.prank(owner);
        proxy.upgradeToAndCall(
            address(implV2),
            abi.encodeCall(CounterV2.initializeV2, (5))
        );
    }

    // ── Group A: V1 basic ─────────────────────────────────────────────────────

    function test_V1_InitialCountIsZero() public {
        assertEq(proxy.count(), 0);
    }

    function test_V1_Inc() public {
        proxy.inc();
        assertEq(proxy.count(), 1);
    }

    function test_V1_Dec() public {
        proxy.inc();
        proxy.dec();
        assertEq(proxy.count(), 0);
    }

    function test_V1_VersionIsV1() public {
        assertEq(proxy.version(), "V1");
    }

    // ── Group B: V1 version history ───────────────────────────────────────────

    function test_V1_VersionHistoryLengthIs1AfterInit() public {
        assertEq(proxy.versionHistoryLength(), 1);
    }

    function test_V1_VersionHistory0IsImplV1() public {
        assertEq(proxy.versionHistory(0), address(implV1));
    }

    function test_V1_CurrentVersionIndexIs0() public {
        assertEq(proxy.currentVersionIndex(), 0);
    }

    // ── Group C: Upgrade to V2 ────────────────────────────────────────────────

    function test_Upgrade_StatePreserved() public {
        proxy.inc();
        proxy.inc();
        assertEq(proxy.count(), 2);

        _upgradeToV2();
        assertEq(proxy.count(), 2);
    }

    function test_Upgrade_VersionHistoryLength2() public {
        _upgradeToV2();
        assertEq(proxy.versionHistoryLength(), 2);
    }

    function test_Upgrade_History1IsImplV2() public {
        _upgradeToV2();
        assertEq(proxy.versionHistory(1), address(implV2));
    }

    function test_Upgrade_CurrentVersionIndexIs1() public {
        _upgradeToV2();
        assertEq(proxy.currentVersionIndex(), 1);
    }

    function test_Upgrade_VersionIsV2() public {
        _upgradeToV2();
        assertEq(proxy.version(), "V2");
    }

    function test_Upgrade_StepSetCorrectly() public {
        _upgradeToV2();
        assertEq(CounterV2(proxyAddr).step(), 5);
    }

    function test_Upgrade_V2IncIncrementsByStep() public {
        _upgradeToV2();
        proxy.inc();
        assertEq(proxy.count(), 5);
    }

    // ── Group D: Rollback ─────────────────────────────────────────────────────

    function test_Rollback_VersionRestoredToV1() public {
        _upgradeToV2();
        vm.prank(owner);
        proxy.rollbackTo(0);
        assertEq(proxy.version(), "V1");
    }

    function test_Rollback_StatePreserved() public {
        proxy.inc();
        _upgradeToV2();
        vm.prank(owner);
        proxy.rollbackTo(0);
        assertEq(proxy.count(), 1);
    }

    function test_Rollback_CurrentVersionIndexUpdated() public {
        _upgradeToV2();
        vm.prank(owner);
        proxy.rollbackTo(0);
        assertEq(proxy.currentVersionIndex(), 0);
    }

    function test_Rollback_VersionHistoryUnchanged() public {
        _upgradeToV2();
        vm.prank(owner);
        proxy.rollbackTo(0);
        assertEq(proxy.versionHistoryLength(), 2);
    }

    function test_Rollback_CanReUpgradeAfterRollback() public {
        _upgradeToV2();
        vm.prank(owner);
        proxy.rollbackTo(0);

        // Deploy a fresh V1 impl; upgrade without init data (Initializable already at version 2)
        CounterV1 implV1b = new CounterV1();
        vm.prank(owner);
        proxy.upgradeToAndCall(address(implV1b), "");

        assertEq(proxy.versionHistoryLength(), 3);
        assertEq(proxy.currentVersionIndex(), 2);
    }

    function test_Rollback_RevertOnOutOfBounds() public {
        vm.prank(owner);
        vm.expectRevert("invalid index");
        proxy.rollbackTo(99);
    }

    // ── Group E: Access control ───────────────────────────────────────────────

    function test_Auth_NonOwnerCannotUpgrade() public {
        vm.prank(alice);
        vm.expectRevert("not owner");
        proxy.upgradeToAndCall(address(implV2), abi.encodeCall(CounterV2.initializeV2, (5)));
    }

    function test_Auth_NonOwnerCannotRollback() public {
        _upgradeToV2();
        vm.prank(alice);
        vm.expectRevert("not owner");
        proxy.rollbackTo(0);
    }

    // ── Group F: Storage layout (namespace isolation) ─────────────────────────

    function test_StorageLayout_Slot0IsZeroAfterV1Init() public {
        // No CounterV1 state lives at slot 0 — proves ERC-7201 namespace isolation.
        bytes32 slot0Value = vm.load(proxyAddr, bytes32(uint256(0)));
        assertEq(slot0Value, bytes32(0));
    }

    function test_StorageLayout_NamespaceSlotHoldsCount() public {
        proxy.inc();
        // count is the first field of CounterStorage, located at COUNTER_STORAGE_SLOT.
        bytes32 raw = vm.load(proxyAddr, keccak256("counter.v1.storage"));
        assertEq(uint256(raw), 1);
    }

    // ── Group G: Reinitializer guards ─────────────────────────────────────────

    function test_Reinit_CannotCallInitializeAgain() public {
        vm.expectRevert();
        proxy.initialize(owner);
    }

    function test_Reinit_CannotCallInitializeV2Twice() public {
        _upgradeToV2();
        vm.expectRevert();
        CounterV2(proxyAddr).initializeV2(10);
    }
}
