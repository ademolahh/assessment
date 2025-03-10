// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { MinimalProxy } from "../src/task-one/MinimalProxy.sol";
import { MinimalProxyAdmin } from "../src/task-one/MinimalProxyAdmin.sol";

import { SimpleStorage, AlreadyInitialized } from "../src/task-one/SimpleStorage.sol";

import { SimpleStorageV2 } from "../src/task-one/SimpleStorageV2.sol";

contract MinimalProxyScript is Script {
    uint256 public constant INITIAL_NUMBER = 10;

    function run() public {
        MinimalProxyAdmin admin = new MinimalProxyAdmin();
        MinimalProxy proxy = new MinimalProxy(address(admin));

        SimpleStorage implementationV1 = new SimpleStorage();

        admin.upgrade(address(proxy), address(implementationV1));

        (bool success,) =
            address(proxy).call(abi.encodeWithSelector(implementationV1.initialize.selector, INITIAL_NUMBER));
        if (!success) revert();
    }
}
