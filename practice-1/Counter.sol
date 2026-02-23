// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title OwnableCounter - Task 1с
contract Counter {
    uint256 private _count;

    uint256 public step;

    constructor(uint256 initialValue, uint256 initialStep) {
        _count = initialValue;
        step = initialStep;
    }

    // external — вызывается только снаружи контракта
    function increment() external {
        _count += step;
    }

    function decrement() external {
        require(_count >= step, "Counter: would underflow");
        _count -= step;
    }

    function reset() public {
        _count = 0;
    }

    function _double() internal view returns (uint256) {
        return _count * 2;
    }

    function _raw() private view returns (uint256) {
        return _count;
    }

    function getCount() external view returns (uint256) {
        return _count;
    }

    function getDouble() external view returns (uint256) {
        return _double();
    }

    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }
}
