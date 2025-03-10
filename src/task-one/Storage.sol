// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

error AlreadyInitialized();

contract Storage {
    uint256 private number;

    bool public initialized;

    modifier initializer() {
        if (initialized) revert AlreadyInitialized();
        initialized = true;
        _;
    }

    function initialize(uint256 _initialNumber) external initializer {
        number = _initialNumber;
    }

    function increase() external {
        number++;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
