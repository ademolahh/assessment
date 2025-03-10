// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IVestedStaking {
    /// @notice Reverts when a user attempts to withdraw more tokens than they have staked.
    error InsufficientBalance();
    /// @notice Reverts when staking is not permitted for the specified token.
    error StakingNotAllowed();
    /// @notice Reverts when the deposit amount is below the required minimum threshold.
    error AmountBelowMinimum();
    /// @notice Reverts when a user attempts to withdraw before the lock period has expired.
    error LockPeriodNotExpired();

    /// @notice Stores information about a user's stake.
    struct Stake {
        /// @param balance The amount of tokens staked by the user.
        uint256 balance;
        /// @param unlockTimeStamp The timestamp when the staked tokens will be unlocked.
        uint256 unlockTimeStamp;
        /// @param lastRewardTimeStamp The timestamp of the last reward calculation.
        uint256 lastRewardTimeStamp;
        /// @param reward The accumulated but unclaimed reward amount.
        uint256 reward;
        /// @param token The address of the token being staked.
        address token;
    }

    /// @notice Stores the configuration settings for staking a specific token.
    struct StakingConfig {
        /// @param isAllowed A flag indicating whether staking is allowed (1 = allowed, 0 = not allowed).
        uint8 isAllowed;
        /// @param lockPeriod The minimum lock duration (in seconds) before staked tokens can be withdrawn.
        uint32 lockPeriod;
    }

    /**
     * @notice Deposits `_amount` of `_token` into the staking contract.
     *  @dev Updates the user's stake balance and adjusts the lock period accordingly.
     *  @param _token The address of the token being staked.
     *  @param _amount The amount of tokens to be staked.
     */
    function deposit(address _token, uint256 _amount) external;

    /**
     * @notice Withdraws `_amount` of `_token` from the staking contract.
     * @dev Ensures the lock period has expired before allowing withdrawal.
     * @param _token The address of the staked token.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(address _token, uint256 _amount) external;

    /**
     * @notice Claims all accrued rewards for staking `_token`.
     * @dev Rewards are calculated based on the staking duration and amount.
     * @param _token The address of the token for which rewards are claimed.
     */
    function claimRewards(address _token) external;

    /**
     * @notice Retrieves the accrued rewards for a given user's stake.
     *  @param _owner The address of the stake owner.
     *  @param _token The address of the token being staked.
     *  @return The amount of rewards accrued.
     */
    function getRewardAccrued(address _owner, address _token) external view returns (uint256);

    /**
     * @notice Updates the staking configuration for a given token.
     *  @param _token The address of the token.
     *  @param _sc The new staking configuration.
     */
    function setStakingConfiguration(address _token, StakingConfig calldata _sc) external;

    /**
     * @dev Returns the latest stake ID for a given user.
     * @param _user The address of the user.
     * @return stakeId The latest stake ID associated with the user.
     */
    function getUserStakeId(address _user) external view returns (uint256 stakeId);

    /**
     * @dev Returns the staking configuration for a given token.
     * @param _token The address of the token.
     * @return config The staking configuration of the token.
     */
    function getStakingConfig(address _token) external view returns (StakingConfig memory config);

    /**
     * @dev Returns the stake details for a given user and stake ID.
     * @param _user The address of the user.
     * @param _stakeId The ID of the stake.
     * @return stakeInfo The stake details for the given user and stake ID.
     */
    function getStakeInfo(address _user, uint256 _stakeId) external view returns (Stake memory stakeInfo);

    /**
     * @dev Returns the stake ID associated with a specific token and user.
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return stakeId The stake ID associated with the user and token.
     */
    function getUserToTokenId(address _user, address _token) external view returns (uint256 stakeId);

    /**
     * @notice Retrieves the total amount of rewards claimed by all users.
     * @dev This function returns the cumulative total of all rewards that have been claimed
     *      by users since the contract's deployment.
     * @return The total rewards claimed across all users.
     */
    function getTotalRewardsClaimed() external view returns (uint256);

    /**
     * @notice Emitted when a user deposits tokens into the staking contract.
     * @param user The address of the user staking tokens.
     * @param token The address of the token being staked.
     * @param newBalance The updated total balance of the user's staked tokens.
     */
    event Deposited(address indexed user, address indexed token, uint256 newBalance);

    /**
     * @notice Emitted when a user withdraws staked tokens.
     * @param user The address of the user withdrawing tokens.
     * @param token The address of the token being withdrawn.
     * @param amount The amount of tokens withdrawn.
     */
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    /**
     * @notice Emitted when staking configuration for a token is updated.
     * @param token The address of the token whose staking configuration is changed.
     * @param stakingConfig The updated staking configuration settings.
     */
    event StakingConfigUpdated(address indexed token, StakingConfig stakingConfig);

    /**
     * @notice Emitted when a user claims staking rewards.
     *  @param user The address of the user claiming rewards.
     *  @param token The address of the token associated with the stake.
     *  @param rewardAmount The amount of rewards claimed.
     */
    event RewardClaimed(address indexed user, address indexed token, uint256 rewardAmount);

    /**
     * @notice Emitted when a user's stake unlock time is updated.
     * @param owner The address of the user whose unlock time is updated.
     * @param token The address of the token being staked.
     * @param newUnlockTime The new timestamp when the staked tokens will become unlocked.
     */
    event UnlockTimeUpdate(address indexed owner, address indexed token, uint256 indexed newUnlockTime);
}
