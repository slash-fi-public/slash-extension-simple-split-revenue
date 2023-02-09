// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../libs/UniversalERC20.sol";

/**
 * @notice Split plugin contract
 */
contract SplitPlugin is OwnableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    uint8 public constant MAX_SPLITS = 10;
    uint16 public constant RATE_PRECISION = 10000;

    address private _operator;
    // Array of wallet to receive payment
    address[] private _splitWallets;
    // Rates for the split wallets
    mapping(address => uint16) private _splitRates;

    event PaymentSplitted(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint16 rate
    );

    error InvalidSplitCount();
    error InvalidSumOfRates();
    error InvalidZeroAddress();
    error NotConfigured();
    error SplitCountMismatch();
    error Unpermitted();

    modifier validatePermission() {
        if (owner() != _msgSender() && _operator != _msgSender())
            revert Unpermitted();
        _;
    }

    /**
     * @notice Initialize plugin
     */
    function initialize(address operator_) public initializer {
        __Ownable_init();

        _operator = operator_;
    }

    /**
     * @notice Configure split wallets and rates
     */
    function configureSplitsData(
        address[] memory splitWallets_,
        uint16[] memory splitRates_
    ) external validatePermission {
        if (splitWallets_.length != splitRates_.length)
            revert SplitCountMismatch();

        uint256 splitCount = splitWallets_.length;
        if (splitCount == 0 || splitCount > MAX_SPLITS)
            revert InvalidSplitCount();

        delete _splitWallets; // Clear split wallets
        uint32 totalRates;
        for (uint256 i = 0; i < splitCount; i++) {
            if (splitWallets_[i] == address(0)) revert InvalidZeroAddress();
            _splitWallets.push(splitWallets_[i]);
            _splitRates[splitWallets_[i]] = splitRates_[i];
            totalRates += splitRates_[i];
        }
        // Sum of rates must be 100% (RATE_PRECISION)
        if (totalRates != RATE_PRECISION) revert InvalidSumOfRates();
    }

    /**
     * @notice Update plugin operator
     * @dev Plugin owner or operator can call this function
     */
    function updateOperator(address operator_) external validatePermission {
        if (operator_ == address(0)) revert InvalidZeroAddress();

        _operator = operator_;
    }

    function viewOperator() external view returns (address) {
        return _operator;
    }

    /**
     * @notice View split wallets and rates
     */
    function viewSplitData()
        external
        view
        returns (address[] memory, uint16[] memory)
    {
        uint256 splitWalletsCount = _splitWallets.length;
        uint16[] memory splitRates = new uint16[](splitWalletsCount);
        for (uint256 i = 0; i < splitWalletsCount; i++) {
            splitRates[i] = _splitRates[_splitWallets[i]];
        }
        return (_splitWallets, splitRates);
    }

    /**
     * @dev receive payment from SlashCore Contract
     * @param receiveToken_: payment receive token
     * @param amount_: payment receive amount
     */
    function receivePayment(
        address receiveToken_,
        uint256 amount_,
        string calldata, /* paymentId: PaymentId generated by the merchant when creating the payment URL */
        string calldata, /* optional: Optional parameter passed at the payment */
        bytes calldata /** reserved */
    ) external payable {
        IERC20Upgradeable(receiveToken_).universalTransferFromSenderToThis(
            amount_
        );

        uint256 splitCount = _splitWallets.length;
        if (splitCount == 0) revert NotConfigured();
        
        for (uint256 i = 0; i < splitCount; i++) {
            uint256 splittedAmount = (amount_ * _splitRates[_splitWallets[i]]) /
                RATE_PRECISION;
            IERC20Upgradeable(receiveToken_).universalTransfer(
                _splitWallets[i],
                splittedAmount
            );
            emit PaymentSplitted(
                _splitWallets[i],
                receiveToken_,
                splittedAmount,
                _splitRates[_splitWallets[i]]
            );
        }
    }

    /**
     * @dev Check if the contract is Slash Plugin
     *
     * Requirement
     * - Implement this function in the contract
     * - Return 1 (v1 extension), 2 (v2 extension)
     */
    function supportSlashExtensionInterface() external pure returns (uint8) {
        return 2;
    }

    // to recieve ETH
    receive() external payable {}

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by Slash owner.
     */
    function recoverWrongTokens(address token_, uint256 amount_)
        external
        onlyOwner
    {
        IERC20Upgradeable(token_).universalTransfer(_msgSender(), amount_);
    }
}
