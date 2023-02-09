// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISlashCustomPlugin.sol";

interface ISlashSplitPlugin is ISlashCustomPlugin {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(address operator)
        external;

    /**
     * @notice Configure split wallets and rates
     */
    function configureSplitsData(
        address[] memory splitWallets_,
        uint16[] memory splitRates_
    ) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}
