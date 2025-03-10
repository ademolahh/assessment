// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { MinimalProxy } from "../src/MinimalProxy.sol";
import { MinimalProxyAdmin } from "../src/MinimalProxyAdmin.sol";
import { Storage, AlreadyInitialized } from "../src/Storage.sol";

contract MinimalProxyTest is Test {
    MinimalProxy mp;
    MinimalProxyAdmin mpa;

    Storage implSone;

    Storage sOne;

    function setUp() public {
        mpa = new MinimalProxyAdmin();
        mp = new MinimalProxy(address(mpa));

        implSone = new Storage();
        mpa.upgrade(address(mp), address(implSone));

        sOne = Storage(address(mp));

        sOne.initialize();
    }

    function testInitializer() public {
        vm.expectRevert();
        sOne.initialize();

        assertEq(sOne.getNumber(), 1);
    }

    function testIncrement() public {
        sOne.increase();

        assertEq(sOne.getNumber(), 2);

        sOne.increase();
        sOne.increase();

        assertEq(sOne.getNumber(), 4);
    }
}
