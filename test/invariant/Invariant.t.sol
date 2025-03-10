// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";

import { Handler } from "./Handler.t.sol";
import { mERC20 } from "../../src/mock/mERC20.sol";
import { VestedStaking } from "../../src/VestedStaking.sol";

contract Invariant is StdInvariant, Test {
    Handler handler;
    VestedStaking vs;
    mERC20 token;

    function setUp() public {
        vs = new VestedStaking();

        token = new mERC20();
        handler = new Handler(vs, token);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.withdraw.selector;
        selectors[2] = handler.claimReward.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));

        targetContract(address(handler));
    }

    function invariantTotal() public view {
        assertEq(vs.getTotalRewardsClaimed(), vs.rewardToken().totalSupply());
    }
}
