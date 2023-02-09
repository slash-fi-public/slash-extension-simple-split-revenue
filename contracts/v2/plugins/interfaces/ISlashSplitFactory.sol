//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISlashSplitFactory {
    /**
     * @notice View current batch contract address
     */
    function viewBatchContract() external view returns (address);
}
