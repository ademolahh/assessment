// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { GoC } from "../src/GoC.sol";

contract GoCTest is Test {
    GoC gc;

    function setUp() public {
        gc = new GoC();
    }

    function testInEfficientLoop() public view {
        uint256[] memory numbers = new uint256[](4);
        numbers[0] = 2;
        numbers[1] = 4;
        numbers[2] = 6;
        numbers[3] = 8;

        assertEq(gc.inefficientLoop(numbers), 20);
    }

    function testEfficientLoop() public view {
        uint256[] memory numbers = new uint256[](4);
        numbers[0] = 2;
        numbers[1] = 4;
        numbers[2] = 6;
        numbers[3] = 8;

        assertEq(gc.efficientLoop(numbers), 20);
    }
}
