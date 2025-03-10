// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import { VestedStaking, IVestedStaking } from "../../src/task-two/VestedStaking.sol";
import { mERC20 } from "../../src/mock/mERC20.sol";

contract VestedStakingFuzzTest is Test {
    VestedStaking staking;
    address tokenOne;

    address iOne = makeAddr("iOne");

    address mToken = makeAddr("mToken");

    uint256 public constant INITIAL_BALANCE = 1_000_000 ether;
    uint32 public constant DEFAULT_LOCK_PERIOD = 30 days;

    function setUp() public {
        staking = new VestedStaking();
        tokenOne = address(new mERC20());

        mERC20(tokenOne).transfer(iOne, INITIAL_BALANCE);

        IVestedStaking.StakingConfig memory scOne =
            IVestedStaking.StakingConfig({ isAllowed: 1, lockPeriod: DEFAULT_LOCK_PERIOD });

        staking.setStakingConfiguration(address(tokenOne), scOne);
    }

    function testFuzzDeposit(uint256 _amount) public {
        _amount = bound(_amount, 1 ether, INITIAL_BALANCE);

        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        staking.deposit(tokenOne, _amount);

        vm.stopPrank();

        IVestedStaking.Stake memory s = staking.getStakeInfo(iOne, 1);

        assertEq(staking.getUserStakeId(iOne), 1);
        assertEq(staking.getUserToTokenId(iOne, tokenOne), 1);

        assertEq(s.balance, _amount);
        assertEq(s.unlockTimeStamp, block.timestamp + DEFAULT_LOCK_PERIOD);
        assertEq(s.lastRewardTimeStamp, block.timestamp);
        assertEq(s.token, tokenOne);
    }

    function testWithdrawal(uint256 _amount) public {
        _amount = bound(_amount, 1 ether, INITIAL_BALANCE);
        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        staking.deposit(tokenOne, _amount);

        vm.warp(10 days);

        vm.warp(DEFAULT_LOCK_PERIOD + 20 days);

        uint256 rewardAccrued = staking.getRewardAccrued(iOne, tokenOne);

        uint256 wAmount = bound(_amount, 1 ether, staking.getStakeInfo(iOne, 1).balance);
        staking.withdraw(tokenOne, wAmount);

        IVestedStaking.Stake memory scOne = staking.getStakeInfo(iOne, 1);
        assertEq(scOne.balance, _amount - wAmount);
        assertEq(scOne.reward, 0);
        assertEq(staking.rewardToken().balanceOf(iOne), rewardAccrued);
        assertEq(staking.rewardToken().totalSupply(), rewardAccrued);

        wAmount = bound(_amount, 0, scOne.balance);

        vm.warp(block.timestamp + 24 hours);
        staking.withdraw(tokenOne, wAmount);

        assertEq(staking.getStakeInfo(iOne, 1).balance, 0);
        assertEq(scOne.reward, 0);

        vm.stopPrank();
    }
}
