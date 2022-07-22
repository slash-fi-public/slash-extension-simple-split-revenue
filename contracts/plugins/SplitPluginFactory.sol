//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/ISlashSplitPlugin.sol";
import "../interfaces/IMerchantProperty.sol";
import "../libs/UniversalERC20.sol";

/**
 * @notice Factory contract for creating Split plugin from the factory model
 * @dev Slash owner will have ownership of this factory as well
 */
contract SplitPluginFactory is OwnableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address private _sharedOwner; // Shared owner over the Split plugins created from this factory
    address private _pluginImpl;

    EnumerableSetUpgradeable.AddressSet private _plugins; // Plugins created
    mapping(address => address) private _merchants2Plugins; // Mapping merchant => plugin

    event NewSplitPluginCreated(
        address indexed account,
        address indexed merchant,
        address indexed plugin
    );

    function initialize(address sharedOwner_, address pluginImpl_)
        public
        initializer
    {
        __Ownable_init();

        _sharedOwner = sharedOwner_;
        _pluginImpl = pluginImpl_;
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
     * @notice Update plugin implementation
     * @dev Only owner can call this function
     */
    function updatePluginImpl(address pluginImpl_) external onlyOwner {
        require(pluginImpl_ != address(0), "Invalid address");
        require(_pluginImpl != pluginImpl_, "Already set");
        _pluginImpl = pluginImpl_;
    }

    /**
     * @notice View current plugin implementation
     */
    function viewPluginImpl() external view returns (address) {
        return _pluginImpl;
    }

    /**
     * @notice View plugin deployed for the merchant contract
     */
    function viewPlugin(address merchant_) external view returns (address) {
        return _merchants2Plugins[merchant_];
    }

    /**
     * @notice Total deployed plugins count
     */
    function totalPluginCount() external view returns (uint256) {
        return _plugins.length();
    }

    /**
     * @notice View deployed plugins (paginated)
     */
    function viewPlugins(uint256 offset, uint256 count)
        external
        view
        returns (address[] memory)
    {
        uint256 pluginsCount = _plugins.length();
        if (offset < pluginsCount && count > 0) {
            count = offset + count > pluginsCount
                ? pluginsCount - offset
                : count;
            address[] memory plugins = new address[](count);
            for (uint256 i = 0; i < count; i++) {
                plugins[i] = _plugins.at(i);
            }
            return plugins;
        }
        return new address[](0);
    }

    /**
     * @notice Deploy Split plugin
     * @param merchantContract_ Merchant contract address
     * @dev Any merchants can deploy plugin for their merchant contract
     */
    function deployPlugin(
        address merchantContract_,
        address[] memory splitWallets_,
        uint16[] memory splitRates_
    ) external {
        address merchantWallet = IMerchantProperty(merchantContract_)
            .viewMerchantWallet();
        // Only Slash owner or merchant owner can deploy split plugin
        require(
            merchantWallet == _msgSender() || _sharedOwner == _msgSender(),
            "Unallowed operation"
        );

        address deployed = ClonesUpgradeable.clone(_pluginImpl);
        ISlashSplitPlugin splitPlugin = ISlashSplitPlugin(deployed);
        splitPlugin.initialize(merchantWallet, merchantContract_);
        splitPlugin.configureSplitsData(splitWallets_, splitRates_);
        splitPlugin.transferOwnership(_sharedOwner);

        _plugins.add(deployed);
        _merchants2Plugins[merchantContract_] = deployed;

        emit NewSplitPluginCreated(merchantWallet, merchantContract_, deployed);
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
