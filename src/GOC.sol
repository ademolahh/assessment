// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract GOC {
    // Identify gas inefficiencies in the function.
    // 1. Checks for the length for each loop
    // 2. Reads from memory(calldata better)
    function inefficientLoop(uint256[] memory numbers) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
    }

    // Rewrite the function to make it more gas-efficient.
    function efficientLoop(uint256[] calldata numbers) public pure returns (uint256 sum) {
        uint256 length = numbers.length;
        uint256 i = 0;

        for (; i < length;) {
            sum += numbers[i];

            unchecked {
                ++i;
            }
        }
    }

    // Explain why your version is better.
    // Function reads input as calldata which is cheaper than reading from memory since it doesn't have to copy all
    // to the memory
    // Using unchecked reduces the cost of i increment since it already has a bound (i < length)
}
