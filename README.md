# Vested Staking - Foundry Test Results

| Test Name                                | Status  | Gas Used |
| ---------------------------------------- | ------- | -------- |
| `testClaimReward()`                      | ✅ PASS | 311,820  |
| `testMultipleDepositWithMultipleToken()` | ✅ PASS | 502,132  |
| `testReward()`                           | ✅ PASS | 292,184  |
| `testSetUp()`                            | ✅ PASS | 36,704   |
| `testSingleDeposit()`                    | ✅ PASS | 240,133  |
| `testWithdrawal()`                       | ✅ PASS | 300,587  |

## Explanation

### `testClaimReward()`

- Ensures that a user can claim staking rewards after a period of time.
- Verifies that the correct reward amount is credited to the user's balance.

### `testMultipleDepositWithMultipleToken()`

- Tests the ability to deposit multiple tokens in multiple transactions.
- Validates that staking periods are correctly handled.

### `testReward()`

- Checks that the reward calculation is accurate based on deposit timestamps.
- Ensures that rewards accrue correctly over time.

### `testSetUp()`

- Validates the initial setup of the staking contract.
- Confirms that staking configurations are correctly assigned.

### `testSingleDeposit()`

- Verifies that a user can deposit a single token and that the correct balance and timestamps are recorded.

### `testWithdrawal()`

- Ensures users can only withdraw after the lock period.
- Validates that the contract correctly handles partial withdrawals and updates balances accordingly.

## Summary

All tests passed successfully, confirming that the **Vested Staking** contract operates as expected. The contract correctly enforces staking rules, calculates rewards, and manages withdrawals based on lock-in periods.

# Invariant Test - Foundry Results

## Overview

This test ensures the **Vested Staking** contract maintains a key invariant: the total claimed rewards should always match the total supply of the reward token. The test utilizes **Forge's invariant testing** to run 5000 test iterations with 160,000 function calls, verifying the contract's integrity under various conditions.

## Test Results

| Test Name          | Runs | Calls   | Reverts | Status  | Execution Time      |
| ------------------ | ---- | ------- | ------- | ------- | ------------------- |
| `invariantTotal()` | 5000 | 160,000 | 0       | ✅ PASS | 13.10s (13.09s CPU) |

## Explanation

### `invariantTotal()`

- This test checks that the **total rewards claimed** by users always equal the **total supply** of the reward token.
- It runs **5000 iterations** and performs **160,000 function calls** to stress test the system.
- The test ensures no unexpected behavior in reward calculations and token supply updates.

## Summary

- **Result:** ✅ All checks passed.
- **Key takeaway:** The `VestedStaking` contract maintains reward integrity under extensive testing.
- **Importance:** This test helps ensure that no unexpected state changes or inconsistencies occur over time.

# GoC - Foundry Test Results

| Test Name               | Status  | Gas Used |
| ----------------------- | ------- | -------- |
| `testEfficientLoop()`   | ✅ PASS | 12,175   |
| `testInEfficientLoop()` | ✅ PASS | 13,578   |

### Suite Result

✅ 2 tests passed; 0 failed; 0 skipped
⏱ Execution time: 5.19ms (1.42ms CPU time)

## Explanation

### `testInEfficientLoop()`

- Tests the inefficient loop implementation.
- Confirms that the function correctly sums up the numbers in an array.
- Uses **13,578 gas**, indicating higher execution cost.

### `testEfficientLoop()`

- Tests the optimized loop implementation.
- Ensures correctness in summing up array elements.
- Uses **12,175 gas**, demonstrating a more gas-efficient approach.

## Summary

The **GoC** contract successfully passed all tests. The optimized loop (`efficientLoop()`) shows **lower gas consumption** compared to the inefficient implementation. This highlights the importance of optimizing Solidity code for gas efficiency.

# Minimal Proxy - Foundry Test Results

## Overview

This test suite verifies the functionality of the **Minimal Proxy** contract, ensuring that it correctly initializes, upgrades, and interacts with storage implementations. The test also checks the proxy's ability to handle function calls properly after an upgrade.

## Test Results

| Test Name           | Gas Used | Status  |
| ------------------- | -------- | ------- |
| `testDecrement()`   | 209,399  | ✅ PASS |
| `testIncrement()`   | 25,224   | ✅ PASS |
| `testInitializer()` | 18,896   | ✅ PASS |

## Explanation

### `testInitializer()`

- Ensures that **re-initialization** of the proxy fails after the first initialization.
- This prevents overwriting of stored values, maintaining state consistency.

### `testIncrement()`

- Calls the `increase()` function on the proxy.
- Verifies that the stored number increments correctly.

### `testDecrement()`

- First, increments the value to ensure a change.
- Upgrades the proxy to **StorageV2**, which includes a `decrease()` function.
- Calls `decrease()` and verifies that the number returns to the initial value.

## Summary

- **Result:** ✅ All tests passed successfully.
- **Key takeaway:** The **Minimal Proxy** functions correctly, including initialization protection and upgradability.
- **Importance:** This ensures that **proxy-based storage contracts** maintain state integrity and upgrade safely.
