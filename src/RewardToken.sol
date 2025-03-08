// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "solady/tokens/ERC20.sol";
import { Ownable } from "solady/auth/Ownable.sol";

/// @notice Thrown when the total supply exceeds the maximum allowable limit.
error MaxSupplyExceeded();

error Unauthorized();

contract RewardToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000_000 ether;

    constructor() {
        _initializeOwner(msg.sender);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        if (totalSupply() + _amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(_to, _amount);
    }

    function name() public view virtual override returns (string memory) {
        return "Reward Token";
    }

    function symbol() public view virtual override returns (string memory) {
        return "RWT";
    }
}
