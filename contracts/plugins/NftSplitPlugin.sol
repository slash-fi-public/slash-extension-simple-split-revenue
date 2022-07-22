//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ISlashSplitPlugin.sol";
import "../libs/UniversalERC20.sol";

/**
 * @notice NFT Split plugin contract
 */
contract NftSplitPlugin is OwnableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    struct NftInfo {
        uint256 chainId;
        uint256 tokenId;
        uint16 splitRate;
        address nftAddress;
        address receipt;
    }

    uint8 public constant MAX_SPLITS = 10;
    uint16 public constant RATE_PRECISION = 10000;

    address private _merchantWallet;
    address private _merchantContract;
    address private _batchContract;

    // NFT info array for the split
    NftInfo[] private _splitNfts;

    event PaymentSplitted(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint16 rate
    );

    /**
     * @notice Initialize plugin
     */
    function initialize(
        address merchantWallet_,
        address merchantContract_,
        address batchContract_
    ) public initializer {
        __Ownable_init();

        _merchantWallet = merchantWallet_;
        _merchantContract = merchantContract_;
        _batchContract = batchContract_;
    }

    /**
     * @notice Update NFT info list
     * @dev Only merchant can update NFT info list
     */
    function updateNftInfoList(
        uint256[] memory chainIds_,
        uint256[] memory tokenIds_,
        address[] memory nftAddresses_,
        uint16[] memory splitRates_
    ) external {
        require(_msgSender() == _merchantWallet, "Unpermitted");
        require(chainIds_.length == tokenIds_.length, "Length different");
        require(chainIds_.length == nftAddresses_.length, "Length different");
        require(chainIds_.length == splitRates_.length, "Length different");

        uint256 splitCount = nftAddresses_.length;
        require(
            splitCount > 0 && splitCount <= MAX_SPLITS,
            "Invalid split count"
        );

        delete _splitNfts; // Clear split wallets
        uint32 totalRates;
        for (uint256 i = 0; i < splitCount; i++) {
            require(nftAddresses_[i] != address(0), "Invalid nft address");
            _splitNfts.push(
                NftInfo({
                    chainId: chainIds_[i],
                    tokenId: tokenIds_[i],
                    nftAddress: nftAddresses_[i],
                    splitRate: splitRates_[i],
                    receipt: address(0)
                })
            );
            totalRates += splitRates_[i];
        }
        // Sum of rates must be 100% (RATE_PRECISION)
        require(totalRates == RATE_PRECISION, "Invalid split rates");
    }

    /**
     * @notice Update receipt list
     * @dev Only batch contract can do this
     */
    function updateReceiptList(address[] memory receipts_) external {
        require(_msgSender() == _batchContract, "Unpermitted");
        require(_splitNfts.length == receipts_.length, "Length different");

        uint256 splitCount = receipts_.length;

        for (uint256 i = 0; i < splitCount; i++) {
            require(receipts_[i] != address(0), "Invalid receipt");
            _splitNfts[i].receipt = receipts_[i];
        }
    }

    /**
     * @notice Update merchant wallet
     * @dev Slash owner or merchant owner can update merchant wallet
     */
    function updateMerchantWallet(address merchantWallet_) external {
        require(
            _msgSender() == owner() || _msgSender() == _merchantWallet,
            "Unpermitted"
        );

        _merchantWallet = merchantWallet_;
    }

    function viewMerchantWallet() external view returns (address) {
        return _merchantWallet;
    }

    /**
     * @notice Update merchant wallet
     * @dev Slash owner or merchant owner can update merchant wallet
     */
    function updateBatchContract(address batchContract_) external {
        require(
            _msgSender() == owner() || _msgSender() == _merchantWallet,
            "Unpermitted"
        );
        _batchContract = batchContract_;
    }

    function viewBachContract() external view returns (address) {
        return _batchContract;
    }

    /**
     * @notice Change merchant contract. This is only for displaying purpose.
     * Allocating merchant contract and plugin contract should be done in the merchant contract
     * @dev Only slash owner can change the merchant contract
     */
    function updateMerchantContract(address merchantContract_)
        external
        onlyOwner
    {
        _merchantContract = merchantContract_;
    }

    function viewMerchantContract() external view returns (address) {
        return _merchantContract;
    }

    /**
     * @notice View split wallets and rates
     */
    function viewNftInfos() external view returns (NftInfo[] memory) {
        require(
            _msgSender() == _merchantWallet || _msgSender() == _batchContract,
            "Unpermitted"
        );
        return _splitNfts;
    }

    /**
     * @dev receive payment from SlashCore Contract
     * @param receiveToken_: payment receive token
     * @param amount_: payment receive amount
     */
    function receivePayment(
        address receiveToken_,
        uint256 amount_,
        string memory, /* paymentId: PaymentId generated by the merchant when creating the payment URL */
        string memory /* optional: Optional parameter passed at the payment */
    ) external payable {
        IERC20Upgradeable(receiveToken_).universalTransferFromSenderToThis(
            amount_
        );

        uint256 splitCount = _splitNfts.length;
        uint32 totalRates;
        for (uint256 i = 0; i < splitCount; i++) {
            uint256 splittedAmount = (amount_ * _splitNfts[i].splitRate) /
                RATE_PRECISION;
            IERC20Upgradeable(receiveToken_).universalTransfer(
                _splitNfts[i].receipt,
                splittedAmount
            );
            totalRates += _splitNfts[i].splitRate;

            emit PaymentSplitted(
                _splitNfts[i].receipt,
                receiveToken_,
                splittedAmount,
                _splitNfts[i].splitRate
            );
        }
        // Sum of rates must be 100% (RATE_PRECISION)
        require(totalRates == RATE_PRECISION, "Invalid split configuration");
    }

    //to recieve ETH
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
