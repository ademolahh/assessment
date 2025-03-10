// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { MinimalProxy } from "../src/task-one/MinimalProxy.sol";
import { MinimalProxyAdmin } from "../src/task-one/MinimalProxyAdmin.sol";

contract MinimalProxyScript is Script {
    function run() public {
        admin = new MinimalProxyAdmin();
        proxy = new MinimalProxy(address(admin));

        implementationV1 = new Storage();

        admin.upgrade(address(proxy), address(implementationV1));

        (bool success,) =
            address(proxy).call(abi.encodeWithSelector(implementationV1.initialize.selector, INITIAL_NUMBER));
        if (!success) revert();
    }
}
