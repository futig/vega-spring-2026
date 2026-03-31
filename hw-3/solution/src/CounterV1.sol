// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable}   from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Utils}    from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

contract CounterV1 is Initializable, UUPSUpgradeable {
    /// @custom:storage-location erc7201:counter.v1
    struct CounterStorage {
        uint256 count;
        address[] versionHistory;
        uint256 currentVersionIndex;
        address owner;
    }

    bytes32 internal constant COUNTER_STORAGE_SLOT = keccak256("counter.v1.storage");

    function _getStorage() internal pure returns (CounterStorage storage $) {
        bytes32 slot = COUNTER_STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        CounterStorage storage $ = _getStorage();
        $.owner = initialOwner;
        $.versionHistory.push(ERC1967Utils.getImplementation());
        $.currentVersionIndex = 0;
    }

    function inc() external virtual {
        _getStorage().count += 1;
    }

    function dec() external virtual {
        _getStorage().count -= 1;
    }

    function count() external view returns (uint256) {
        return _getStorage().count;
    }

    function version() external pure virtual returns (string memory) {
        return "V1";
    }

    function owner() external view returns (address) {
        return _getStorage().owner;
    }

    function versionHistory(uint256 index) external view returns (address) {
        return _getStorage().versionHistory[index];
    }

    function versionHistoryLength() external view returns (uint256) {
        return _getStorage().versionHistory.length;
    }

    function currentVersionIndex() external view returns (uint256) {
        return _getStorage().currentVersionIndex;
    }

    function rollbackTo(uint256 index) external {
        CounterStorage storage $ = _getStorage();
        require(msg.sender == $.owner, "not owner");
        require(index < $.versionHistory.length, "invalid index");
        ERC1967Utils.upgradeToAndCall($.versionHistory[index], "");
        $.currentVersionIndex = index;
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        CounterStorage storage $ = _getStorage();
        require(msg.sender == $.owner, "not owner");
        $.versionHistory.push(newImplementation);
        $.currentVersionIndex = $.versionHistory.length - 1;
    }
}
