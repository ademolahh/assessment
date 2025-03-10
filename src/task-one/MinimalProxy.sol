// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IMinimalProxy } from "../interfaces/IMinimalProxy.sol";

contract MinimalProxy is IMinimalProxy {
    //  bytes32(uint256(keccak256("MinimalProxy.proxy.implementation")) - 1);
    bytes32 private constant IMPLEMENTATION_SLOT = 0x095e2f240b5b350e237b5487117d08a4c7be897f1feb1382dce558bde88b8e33;

    //  bytes32(uint256(keccak256("MinimalProxy.proxy.admin")) - 1);
    bytes32 private constant ADMIN_SLOT = 0xc5b128251efcea3ca8285a39cab7b5003a4dddca495b36b4111e1c829c51ef89;

    constructor(address _admin) {
        assembly {
            sstore(ADMIN_SLOT, _admin)
        }
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        return _delegate(data);
    }

    function _delegate(bytes calldata data) internal returns (bytes memory) {
        address implementation;

        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }

        if (implementation == address(0)) revert InvalidImplementationAddress();

        (bool success, bytes memory res) = implementation.delegatecall(data);

        if (!success) revert DelegateCallFailed();

        return res;
    }

    function getImplementation() external view returns (address) {
        address impl;
        assembly {
            impl := sload(IMPLEMENTATION_SLOT)
        }

        return impl;
    }

    function upgradeTo(address _newImplementation) external {
        _isAdmin(msg.sender);
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
    }

    function _isAdmin(address _caller) internal view {
        address admin;

        assembly {
            admin := sload(ADMIN_SLOT)
        }

        if (admin != _caller) revert Unauthorized();
    }
}
