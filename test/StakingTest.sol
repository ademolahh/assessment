// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { Staking, IStaking } from "../src/Staking.sol";
import { mERC20 } from "../src/mock/mERC20.sol";

contract StakingTest is Test {
    Staking staking;
    address tokenOne;
    address tokenTwo;

    address iOne = makeAddr("iOne");
    address iTwo = makeAddr("iTwo");

    address mToken = makeAddr("mToken");

    uint256 public constant INITIAL_BALANCE = 1_000_000 ether;
    uint32 public constant DEFAULT_LOCK_PERIOD = 30 days;

    function setUp() public {
        staking = new Staking();
        tokenOne = address(new mERC20());
        tokenTwo = address(new mERC20());

        mERC20(tokenOne).transfer(iOne, INITIAL_BALANCE);
        mERC20(tokenOne).transfer(iTwo, INITIAL_BALANCE);

        mERC20(tokenTwo).transfer(iOne, INITIAL_BALANCE);
        mERC20(tokenTwo).transfer(iTwo, INITIAL_BALANCE);

        IStaking.StakingConfig memory scOne = IStaking.StakingConfig({ isAllowed: 1, lockPeriod: DEFAULT_LOCK_PERIOD });
        IStaking.StakingConfig memory scTwo = IStaking.StakingConfig({ isAllowed: 1, lockPeriod: DEFAULT_LOCK_PERIOD });

        staking.setStakingConfiguration(address(tokenOne), scOne);
        staking.setStakingConfiguration(address(tokenTwo), scTwo);
    }

    function testSetUp() public view {
        assertNotEq(address(staking.rewardToken()), address(0));
        IStaking.StakingConfig memory scOne = staking.getStakingConfig(tokenOne);
        IStaking.StakingConfig memory scTwo = staking.getStakingConfig(tokenTwo);
        assertEq(scOne.isAllowed, 1);
        assertEq(scTwo.isAllowed, 1);

        assertEq(scOne.lockPeriod, DEFAULT_LOCK_PERIOD);
        assertEq(scTwo.lockPeriod, DEFAULT_LOCK_PERIOD);
    }

    function testSingleDeposit() public {
        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        uint256 amount = 1_000 ether;

        vm.expectRevert(IStaking.StakingNotAllowed.selector);
        staking.deposit(address(1), amount);

        vm.expectRevert(IStaking.AmountBelowMinimum.selector);
        staking.deposit(tokenOne, 1);

        staking.deposit(tokenOne, amount);

        vm.stopPrank();

        IStaking.Stake memory s = staking.getStakeInfo(iOne, 1);

        assertEq(staking.getUserStakeId(iOne), 1);
        assertEq(staking.getUserToTokenId(iOne, tokenOne), 1);

        assertEq(s.balance, amount);
        assertEq(s.unlockTimeStamp, block.timestamp + DEFAULT_LOCK_PERIOD);
        assertEq(s.lastRewardTimeStamp, block.timestamp);
        assertEq(s.token, tokenOne);
    }

    function testMultipleDepositWithMultipleToken() public {
        vm.startPrank(iTwo);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);
        mERC20(tokenTwo).approve(address(staking), INITIAL_BALANCE);

        uint256 amount = 1_000 ether;
        staking.deposit(tokenOne, amount); // 1

        vm.warp(block.timestamp + 24 hours);

        staking.deposit(tokenTwo, amount); // 2
        uint256 t2InitialTime = block.timestamp + DEFAULT_LOCK_PERIOD;

        vm.warp(block.timestamp + 24 hours);

        staking.deposit(tokenOne, amount); // 3
        uint256 t1NextTime = block.timestamp + DEFAULT_LOCK_PERIOD;

        vm.warp(block.timestamp + 24 hours);

        staking.deposit(tokenTwo, amount); // 4
        uint256 t2NextTime = block.timestamp + DEFAULT_LOCK_PERIOD;

        vm.stopPrank();

        IStaking.Stake memory sOne = staking.getStakeInfo(iTwo, 1);
        IStaking.Stake memory sTwo = staking.getStakeInfo(iTwo, 2);

        uint256 t1 = _latestTime(amount, amount, DEFAULT_LOCK_PERIOD, t1NextTime) / 1 days;
        uint256 t2 = _latestTime(amount, amount, t2InitialTime, t2NextTime) / 1 days;

        assertEq(staking.getUserStakeId(iTwo), 2);
        assertEq(staking.getUserToTokenId(iTwo, tokenOne), 1);
        assertEq(staking.getUserToTokenId(iTwo, tokenTwo), 2);

        assertEq(sOne.balance, 2 * amount);
        assertEq(sOne.unlockTimeStamp / 1 days, t1);
        assertEq(sOne.token, tokenOne);

        assertEq(sTwo.balance, 2 * amount);
        assertEq(sTwo.unlockTimeStamp / 1 days, t2);
        assertEq(sTwo.token, tokenTwo);
    }

    function testReward() public {
        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        uint256 amount = 1_000 ether;

        staking.deposit(tokenOne, amount); // 1

        vm.warp(block.timestamp + 24 hours);

        assertEq(staking.getRewardAccrued(iOne, tokenOne), amount);

        staking.deposit(tokenOne, amount); // 2

        assertEq(staking.getStakeInfo(iOne, 1).reward, amount);

        vm.warp(block.timestamp + 24 hours);

        assertEq(staking.getRewardAccrued(iOne, tokenOne), amount * 3);

        staking.deposit(tokenOne, amount); // 3

        vm.warp(block.timestamp + 24 hours);

        // 3000 -> 1 , 2000 -> 2, 1000 -> 3

        assertEq(staking.getRewardAccrued(iOne, tokenOne), amount * 6);

        vm.stopPrank();
    }

    function testClaimReward() public {
        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        uint256 amount = 1_000 ether;

        staking.deposit(tokenOne, amount); // 1

        uint256 iOneBalanceBefore = staking.rewardToken().balanceOf(iOne);

        vm.warp(10 days);

        uint256 rewardAccrued = staking.getRewardAccrued(iOne, tokenOne);
        staking.claimRewards(tokenOne);

        vm.stopPrank();

        uint256 iOneBalanceAfter = staking.rewardToken().balanceOf(iOne);

        assertEq(iOneBalanceAfter, iOneBalanceBefore + rewardAccrued);
    }

    function testWithdrawal() public {
        vm.startPrank(iOne);
        mERC20(tokenOne).approve(address(staking), INITIAL_BALANCE);

        uint256 amount = 1_000 ether;

        staking.deposit(tokenOne, amount); // 1

        vm.warp(24 hours);

        staking.deposit(tokenOne, amount);

        vm.warp(10 days);

        vm.expectRevert(IStaking.LockPeriodNotExpired.selector);
        staking.withdraw(tokenOne, amount);

        vm.warp(DEFAULT_LOCK_PERIOD + 20 days);

        uint256 rewardAccrued = staking.getRewardAccrued(iOne, tokenOne);
        staking.withdraw(tokenOne, amount);

        IStaking.Stake memory scOne = staking.getStakeInfo(iOne, 1);
        assertEq(scOne.balance, amount);
        assertEq(scOne.reward, 0);
        assertEq(staking.rewardToken().balanceOf(iOne), rewardAccrued);
        assertEq(staking.rewardToken().totalSupply(), rewardAccrued);

        vm.expectRevert(IStaking.InsufficientBalance.selector);
        staking.withdraw(tokenOne, amount + 1);

        vm.warp(block.timestamp + 24 hours);
        staking.withdraw(tokenOne, amount);

        assertEq(staking.getStakeInfo(iOne, 1).balance, 0);
        assertEq(scOne.reward, 0);

        vm.stopPrank();
    }

    /**
     * @dev Computes the weighted average time based on two balances and their respective timestamps.
     * @notice This function is useful for calculating the latest effective time when merging two staking periods.
     * @param _b1 The first balance.
     * @param _b2 The second balance.
     * @param _t1 The timestamp associated with `_b1`.
     * @param _t2 The timestamp associated with `_b2`.
     * @return latestTime The weighted average timestamp based on `_b1` and `_b2`.
     *
     * @dev Formula: ((_b1 * _t1) + (_b2 * _t2)) / (_b1 + _b2)
     *      Ensures that larger balances contribute more to the resulting time.
     */
    function _latestTime(uint256 _b1, uint256 _b2, uint256 _t1, uint256 _t2) internal pure returns (uint256) {
        return ((_b1 * _t1) + (_b2 * _t2)) / (_b1 + _b2);
    }
}
