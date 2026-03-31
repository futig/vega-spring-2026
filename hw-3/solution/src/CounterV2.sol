// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CounterV1} from "./CounterV1.sol";

contract CounterV2 is CounterV1 {
    uint256 public step;

    function initializeV2(uint256 initialStep) external reinitializer(2) {
        require(initialStep > 0, "step must be positive");
        step = initialStep;
    }

    function inc() external override {
        _getStorage().count += step;
    }

    function dec() external override {
        _getStorage().count -= step;
    }

    function version() external pure override returns (string memory) {
        return "V2";
    }
}
