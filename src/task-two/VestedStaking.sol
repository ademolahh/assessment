// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { Ownable } from "solady/auth/Ownable.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { IVestedStaking } from "../interfaces/IVestedStaking.sol";
import { RewardToken } from "./RewardToken.sol";

/**
 * @title YieldStaking
 * @author Ademola
 * @notice A flexible ERC-20 staking contract that allows users to stake tokens, earn rewards,
 *         and withdraw staked tokens after a lock period. The contract dynamically adjusts
 *         the lock period using Weighted Average Lock Calculation (WALC) to provide a
 *         fair staking experience.
 *
 * @dev Implements Weighted Average Lock Calculation (WALC) to dynamically determine
 *      the remaining lock period when additional tokens are staked. Supports time-based
 *      reward distribution and ensures secure staking with claimable rewards.
 */
contract VestedStaking is IVestedStaking, Ownable {
    using SafeTransferLib for address;
    using FixedPointMathLib for uint256;

    uint256 private totalRewardsClaimed;

    /// @notice The address of the token used for rewards distribution.
    RewardToken public rewardToken;

    /// @notice The minimum amount of tokens that can be staked.
    uint256 public constant MINIMUM_AMOUNT = 1;

    /// @notice The reward rate per token staked, denominated in wei.
    uint256 public constant REWARD_PER_TOKEN_STAKED = 1 ether;

    /// @notice Tracks the current stake ID for each user.
    /// @dev Maps a user's address to their latest stake ID.
    mapping(address user => uint256 id) private userStakeId;

    /// @notice Stores staking configuration for each token.
    /// @dev Maps a token address to its staking configuration.
    mapping(address token => StakingConfig config) private stakingConfig;

    /// @notice Stores stake details for each user and stake ID.
    /// @dev Maps a user's address and stake ID to their Stake struct.
    mapping(address user => mapping(uint256 id => Stake stakeInfo)) private stake;

    /// @notice Tracks the stake ID associated with user token for a each user.
    /// @dev Maps a token address and user address to the stake ID.
    mapping(address user => mapping(address token => uint256 id)) private tokenToUserId;

    constructor() {
        _initializeOwner(msg.sender);
        rewardToken = new RewardToken();
    }

    /// @inheritdoc IVestedStaking
    function deposit(address _token, uint256 _amount) external {
        StakingConfig memory sc = stakingConfig[_token];
        if (sc.isAllowed != 1) revert StakingNotAllowed();
        if (_amount < MINIMUM_AMOUNT * IERC20(_token).decimals()) revert AmountBelowMinimum();

        uint256 currentId = userStakeId[msg.sender];
        uint256 tId = tokenToUserId[msg.sender][_token];
        if (tId == 0) {
            tId = currentId + 1;
            userStakeId[msg.sender]++;
            tokenToUserId[msg.sender][_token] = tId;
        }

        Stake memory s = stake[msg.sender][tId];

        if (s.balance == 0) {
            s.token = _token;
            s.unlockTimeStamp = block.timestamp + sc.lockPeriod;
        } else {
            s.reward += _calculateReward(s);
            s.unlockTimeStamp = _updateTime(s, _amount, sc.lockPeriod);
            emit UnlockTimeUpdate(msg.sender, _token, s.lastRewardTimeStamp);
        }
        s.balance += _amount;
        s.lastRewardTimeStamp = block.timestamp;

        stake[msg.sender][tId] = s;
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(msg.sender, _token, s.balance);
    }

    /// @inheritdoc IVestedStaking
    function withdraw(address _token, uint256 _amount) external {
        uint256 tId = tokenToUserId[msg.sender][_token];
        Stake memory s = stake[msg.sender][tId];

        if (block.timestamp < s.unlockTimeStamp) revert LockPeriodNotExpired();

        if (_amount > s.balance) revert InsufficientBalance();
        if (getRewardAccrued(msg.sender, _token) > 0) {
            claimRewards(_token);
        }

        s.balance -= _amount;
        if (s.balance == 0) {
            s.unlockTimeStamp = 0;
            s.lastRewardTimeStamp = 0;
        }
        stake[msg.sender][tId] = s;

        _token.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _token, _amount);
    }

    /// inheritdoc IVestedStaking
    function claimRewards(address _token) public {
        uint256 tId = tokenToUserId[msg.sender][_token];
        uint256 amount = getRewardAccrued(msg.sender, _token);

        stake[msg.sender][tId].reward = 0;
        stake[msg.sender][tId].lastRewardTimeStamp = block.timestamp;

        totalRewardsClaimed += amount;
        rewardToken.mint(msg.sender, amount);
        emit RewardClaimed(msg.sender, _token, amount);
    }

    /// @inheritdoc IVestedStaking
    function getRewardAccrued(address _user, address _token) public view returns (uint256) {
        uint256 tId = tokenToUserId[_user][_token];
        Stake memory s = stake[_user][tId];
        return _calculateReward(s) + s.reward;
    }

    /**
     * @notice Calculates the updated lock period based on the current balance and newly deposited amount.
     * @dev Uses a weighted average approach to adjust the lock period dynamically.
     * @param _s The stake data of the user.
     * @param _amount The newly deposited amount.
     * @param _lockPeriod The lock period of the staking configuration for the token.
     * @return The new lock timestamp after considering the weighted lock period.
     */
    function _updateTime(Stake memory _s, uint256 _amount, uint256 _lockPeriod) internal view returns (uint256) {
        uint256 currentTimeLeft = _s.unlockTimeStamp > block.timestamp ? _s.unlockTimeStamp - block.timestamp : 0;
        uint256 time = ((_s.balance * currentTimeLeft) + (_amount * _lockPeriod)) / (_s.balance + _amount);
        return time + block.timestamp;
    }

    /**
     * @notice Calculates the reward accrued for a given stake.
     * @dev Rewards are calculated based on the time elapsed and the amount of tokens staked.
     * @param _s The stake data of the user.
     * @return The total reward accrued up to the current block timestamp.
     */
    function _calculateReward(Stake memory _s) internal view returns (uint256) {
        uint256 aTime = (block.timestamp - _s.lastRewardTimeStamp) / 1 days;
        return REWARD_PER_TOKEN_STAKED.mulWad(_s.balance * aTime);
    }

    /// @inheritdoc IVestedStaking
    function setStakingConfiguration(address _token, StakingConfig calldata _sc) external onlyOwner {
        stakingConfig[_token] = _sc;
        emit StakingConfigUpdated(_token, _sc);
    }

    /// @inheritdoc IVestedStaking
    function getUserStakeId(address _user) external view returns (uint256 stakeId) {
        return userStakeId[_user];
    }

    /// @inheritdoc IVestedStaking
    function getStakingConfig(address _token) external view returns (StakingConfig memory config) {
        return stakingConfig[_token];
    }

    /// @inheritdoc IVestedStaking
    function getStakeInfo(address _user, uint256 _stakeId) external view returns (Stake memory stakeInfo) {
        return stake[_user][_stakeId];
    }

    /// @inheritdoc IVestedStaking
    function getUserToTokenId(address _user, address _token) external view returns (uint256 stakeId) {
        return tokenToUserId[_user][_token];
    }

    /// @inheritdoc IVestedStaking
    function getTotalRewardsClaimed() external view returns (uint256) {
        return totalRewardsClaimed;
    }
}
