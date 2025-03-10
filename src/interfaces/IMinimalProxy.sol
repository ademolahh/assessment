// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMinimalProxy {
    /// @notice Reverts when an unauthorized user attempts to perform a restricted action.
    error Unauthorized();

    /// @notice Reverts when a low-level delegate call fails.
    error DelegateCallFailed();

    /// @notice Reverts when an invalid implementation address is provided.
    error InvalidImplementationAddress();

    /**
     * @notice Upgrades the contract implementation to `_newImplementation`.
     * @dev Allows authorized users to change the contract logic by setting a new
     *      implementation address. This function ensures that the provided address is
     *      valid before proceeding with the upgrade.
     * @param _newImplementation The address of the new contract implementation.
     */
    function upgradeTo(address _newImplementation) external;

    /**
     * @notice Retrieves the current contract implementation address.
     * @dev This function returns the address of the contract that is currently
     *      being used as the implementation.
     * @return The address of the active implementation contract.
     */
    function getImplementation() external view returns (address);
}
