// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Ownable.sol";

/// @title OwnableCounter - Task 3
contract OwnableCounter is Ownable {
    uint256 private _count;

    constructor(uint256 initialValue) {
        _count = initialValue;
    }

    function increment() external onlyOwner {
        _count += 1;
    }

    function decrement() external onlyOwner {
        require(_count > 0, "OwnableCounter: already at zero");
        _count -= 1;
    }

    function getCount() external view returns (uint256) {
        return _count;
    }
}
