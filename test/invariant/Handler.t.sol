// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { VestedStaking, IVestedStaking } from "../../src/VestedStaking.sol";
import { mERC20 } from "../../src/mock/mERC20.sol";

contract Handler is Test {
    mERC20 token;
    VestedStaking vs;

    address caller;

    uint256 callersBalance;

    uint256 public constant INITIAL_BALANCE = 1_000_000 ether;
    uint32 public constant DEFAULT_LOCK_PERIOD = 30 days;

    uint256 public immutable MINIMUM;

    constructor(VestedStaking _vs, mERC20 _token) {
        vs = _vs;
        token = _token;

        caller = makeAddr("caller");

        MINIMUM = 1 * mERC20(token).decimals();

        vm.startPrank(msg.sender);
        mERC20(token).transfer(caller, INITIAL_BALANCE);

        IVestedStaking.StakingConfig memory scOne =
            IVestedStaking.StakingConfig({ isAllowed: 1, lockPeriod: DEFAULT_LOCK_PERIOD });
        IVestedStaking.StakingConfig memory scTwo =
            IVestedStaking.StakingConfig({ isAllowed: 1, lockPeriod: DEFAULT_LOCK_PERIOD });

        vs.setStakingConfiguration(address(token), scOne);
        vs.setStakingConfiguration(address(token), scTwo);
        vm.stopPrank();
    }

    function deposit(uint256 _amount) public {
        if (token.balanceOf(caller) > MINIMUM) {
            _amount = bound(_amount, MINIMUM, token.balanceOf(caller));

            vm.startPrank(caller);
            mERC20(token).approve(address(vs), INITIAL_BALANCE);
            vs.deposit(address(token), _amount);
            vm.stopPrank();
            callersBalance += _amount;
        }
    }

    function withdraw(uint256 _amount) public {
        if (callersBalance > 0) {
            vm.startPrank(caller);
            _amount = bound(_amount, 0, callersBalance);
            vm.warp(block.timestamp + 1 + DEFAULT_LOCK_PERIOD);
            vs.withdraw(address(token), _amount);
            callersBalance -= _amount;
            vm.stopPrank();
        }
    }

    function claimReward() public {
        vm.startPrank(caller);
        if (callersBalance > 0) {
            vs.claimRewards(address(token));
        }
        vm.stopPrank();
    }
}
