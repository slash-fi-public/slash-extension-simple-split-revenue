// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISlashCustomPlugin.sol";

interface ISlashNftSplitPlugin is ISlashCustomPlugin {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(address operator) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}
