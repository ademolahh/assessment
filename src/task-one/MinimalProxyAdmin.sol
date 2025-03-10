// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IMinimalProxy } from "../interfaces/IMinimalProxy.sol";
import { Ownable } from "solady/auth/Ownable.sol";

contract MinimalProxyAdmin is Ownable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    constructor() {
        _initializeOwner(msg.sender);
    }

    function upgrade(address _proxy, address _implementation) external onlyOwner {
        address oldImplementation = IMinimalProxy(_proxy).getImplementation();
        IMinimalProxy(_proxy).upgradeTo(_implementation);
        emit Upgraded(oldImplementation, _implementation);
    }
}
