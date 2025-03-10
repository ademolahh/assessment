// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { VestedStaking } from "../src/task-two/VestedStaking.sol";

contract VestedStakingScript is Script {
    function run() public returns (address) {
        vm.startBroadcast();
        VestedStaking vs = new VestedStaking();

        vm.stopBroadcast();

        return address(vs);
    }
}
