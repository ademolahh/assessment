// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { MinimalProxy } from "../src/task-one/MinimalProxy.sol";
import { MinimalProxyAdmin } from "../src/task-one/MinimalProxyAdmin.sol";
import { Storage, AlreadyInitialized } from "../src/task-one/Storage.sol";

import { StorageV2 } from "../src/task-one/StorageV2.sol";

contract MinimalProxyTest is Test {
    MinimalProxy proxy;
    MinimalProxyAdmin admin;

    Storage implementationV1;

    Storage sOne;

    uint256 public constant INITIAL_NUMBER = 15;

    function setUp() public {
        admin = new MinimalProxyAdmin();
        proxy = new MinimalProxy(address(admin));

        implementationV1 = new Storage();

        admin.upgrade(address(proxy), address(implementationV1));

        (bool success,) =
            address(proxy).call(abi.encodeWithSelector(implementationV1.initialize.selector, INITIAL_NUMBER));
        if (!success) revert();
    }

    function testInitializer() public {
        (bool success,) =
            address(proxy).call(abi.encodeWithSelector(implementationV1.initialize.selector, INITIAL_NUMBER));

        assertFalse(success);
    }

    function testIncrement() public {
        (bool success,) = address(proxy).call(abi.encodeWithSelector(implementationV1.increase.selector));
        assertTrue(success);

        (bool ok, bytes memory data) = address(proxy).call(abi.encodeWithSelector(implementationV1.getNumber.selector));
        assertTrue(ok);

        assertEq(abi.decode(data, (uint256)), INITIAL_NUMBER + 1);
    }

    function testDecrement() public {
        (bool ok,) = address(proxy).call(abi.encodeWithSelector(implementationV1.increase.selector));
        assertTrue(ok);
        StorageV2 implementationV2 = new StorageV2();
        admin.upgrade(address(proxy), address(implementationV2));

        (bool success,) = address(proxy).call(abi.encodeWithSelector(implementationV2.decrease.selector));
        assertTrue(success);

        (bool pass, bytes memory data) =
            address(proxy).call(abi.encodeWithSelector(implementationV1.getNumber.selector));
        assertTrue(pass);

        assertEq(abi.decode(data, (uint256)), INITIAL_NUMBER);
    }
}
