//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/ISlashSplitPlugin.sol";
import "./interfaces/ISlashNftSplitPlugin.sol";
import "../interfaces/IMerchantProperty.sol";
import "../libs/UniversalERC20.sol";

/**
 * @notice Factory contract for creating Split plugin from the factory model
 * @dev Slash owner will have ownership of this factory as well
 */
contract SplitPluginFactory is OwnableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    address private _sharedOwner; // Shared owner over the Split plugins created from this factory
    address private _splitPluginImpl;
    address private _nftSplitPluginImpl;
    address private _batchContract;

    event NewSplitPluginCreated(
        address indexed account,
        address indexed plugin
    );
    event NewNftSplitPluginCreated(
        address indexed account,
        address indexed plugin
    );

    function initialize(
        address sharedOwner_,
        address splitPluginImpl_,
        address nftSplitPluginImpl_
    ) public initializer {
        __Ownable_init();

        _sharedOwner = sharedOwner_;
        _splitPluginImpl = splitPluginImpl_;
        _nftSplitPluginImpl = nftSplitPluginImpl_;
    }

    /**
     * @notice Update shared owner
     * @param sharedOwner_ new shared owner account
     * @dev Only onwer can call this function
     */
    function updateSharedOwner(address sharedOwner_) external onlyOwner {
        require(sharedOwner_ != address(0), "Invalid address");
        require(_sharedOwner != sharedOwner_, "Already set");
        _sharedOwner = sharedOwner_;
    }

    /**
     * @notice View current shared owner address
     */
    function viewSharedOwner() external view returns (address) {
        return _sharedOwner;
    }

    /**
     * @notice Update shared owner
     * @param contract_ new batch contract address
     * @dev Only onwer can call this function
     */
    function updateBatchContract(address contract_) external onlyOwner {
        require(contract_ != address(0), "Invalid address");
        _batchContract = contract_;
    }

    /**
     * @notice View current batch contract address
     */
    function viewBatchContract() external view returns (address) {
        return _batchContract;
    }

    /**
     * @notice Update split plugin implementation
     * @dev Only owner can call this function
     */
    function updateSplitPluginImpl(address pluginImpl_) external onlyOwner {
        require(pluginImpl_ != address(0), "Invalid address");
        _splitPluginImpl = pluginImpl_;
    }

    /**
     * @notice View current split plugin implementation
     */
    function viewSplitPluginImpl() external view returns (address) {
        return _splitPluginImpl;
    }

    /**
     * @notice Update nft split plugin implementation
     * @dev Only owner can call this function
     */
    function updateNftSplitPluginImpl(address pluginImpl_) external onlyOwner {
        require(pluginImpl_ != address(0), "Invalid address");
        _nftSplitPluginImpl = pluginImpl_;
    }

    /**
     * @notice View current nft split plugin implementation
     */
    function viewNftSplitPluginImpl() external view returns (address) {
        return _nftSplitPluginImpl;
    }

    /**
     * @notice Deploy Split plugin
     */
    function deploySplitPlugin(
        address[] memory splitWallets_,
        uint16[] memory splitRates_
    ) external {
        address deployed = ClonesUpgradeable.clone(_splitPluginImpl);
        ISlashSplitPlugin splitPlugin = ISlashSplitPlugin(deployed);
        splitPlugin.initialize(_msgSender());
        splitPlugin.configureSplitsData(splitWallets_, splitRates_);
        splitPlugin.transferOwnership(_sharedOwner); // Shared owner will have all ownership of plugins

        emit NewSplitPluginCreated(_msgSender(), deployed);
    }

    /**
     * @notice Deploy Nft Split plugin
     */
    function deployNftSplitPlugin() external {
        address deployed = ClonesUpgradeable.clone(_nftSplitPluginImpl);
        ISlashNftSplitPlugin nftSplitPlugin = ISlashNftSplitPlugin(deployed);
        nftSplitPlugin.initialize(_msgSender());
        nftSplitPlugin.transferOwnership(_sharedOwner); // Shared owner will have all ownership of plugins

        emit NewNftSplitPluginCreated(_msgSender(), deployed);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address token_, uint256 amount_)
        external
        onlyOwner
    {
        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }
}
