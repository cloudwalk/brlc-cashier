// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import { BlocklistableUpgradeable } from "./base/BlocklistableUpgradeable.sol";
import { PausableExtUpgradeable } from "./base/PausableExtUpgradeable.sol";
import { RescuableUpgradeable } from "./base/RescuableUpgradeable.sol";
import { StoragePlaceholder200 } from "./base/StoragePlaceholder200.sol";
import { AccessControlExtUpgradeable } from "./base/AccessControlExtUpgradeable.sol";

import { PixCashierStorage } from "./PixCashierStorage.sol";
import { IPixCashier } from "./interfaces/IPixCashier.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";

/**
 * @title PixCashier contract
 * @dev Wrapper contract for PIX cash-in and cash-out operations.
 *
 * Only accounts that have {CASHIER_ROLE} role can execute the cash-in operations and process the cash-out operations.
 * About roles see https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl.
 */
contract PixCashier is
    AccessControlExtUpgradeable,
    BlocklistableUpgradeable,
    PausableExtUpgradeable,
    RescuableUpgradeable,
    StoragePlaceholder200,
    PixCashierStorage,
    IPixCashier
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    /// @dev The role of this contract owner.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev The role of cashier that is allowed to execute the cash-in operations.
    bytes32 public constant CASHIER_ROLE = keccak256("CASHIER_ROLE");

    // -------------------- Errors -----------------------------------

    /// @dev The zero token address has been passed as a function argument.
    error ZeroTokenAddress();

    /// @dev The zero account has been passed as a function argument.
    error ZeroAccount();

    /// @dev The zero token amount has been passed as a function argument.
    error ZeroAmount();

    /// @dev The zero off-chain transaction identifier has been passed as a function argument.
    error ZeroTxId();

    /// @dev The zero off-chain transaction batch identifier has been passed as a function argument.
    error ZeroBatchId();

    /// @dev An empty array of off-chain transaction identifiers has been passed as a function argument.
    error EmptyTransactionIdsArray();

    /// @dev The minting of tokens failed when processing an `cashIn` operation.
    error TokenMintingFailure();

    /// @dev The length of the one of the batch arrays is different to the others.
    error InvalidBatchArrays();

    /**
     * @dev The cash-in operation with the provided off-chain transaction is already executed.
     * @param txId The off-chain transaction identifiers of the operation.
     */
    error CashInAlreadyExecuted(bytes32 txId);

    /**
     * @dev The cash-in batch operation with the provided off-chain transaction is already executed.
     * @param batchId The off-chain transaction identifiers of the operation.
     */
    error CashInBatchAlreadyExecuted(bytes32 batchId);

    /**
     * @dev The cash-out operation with the provided off-chain transaction identifier has an inappropriate status.
     * @param txId The off-chain transaction identifiers of the operation.
     * @param status The current status of the operation.
     */
    error InappropriateCashOutStatus(bytes32 txId, CashOutStatus status);

    /**
     * @dev The cash-out operation with the provided txId cannot executed for the given account.
     * @param txId The off-chain transaction identifiers of the operation.
     * @param account The account that must be used for the operation.
     */
    error InappropriateCashOutAccount(bytes32 txId, address account);

    // -------------------- Functions --------------------------------

    /**
     * @dev The initialize function of the upgradable contract.
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
     *
     * Requirements:
     *
     * - The passed token address must not be zero.
     *
     * @param token_ The address of the token to set as the underlying one.
     */
    function initialize(address token_) external initializer {
        __PixCashier_init(token_);
    }

    function __PixCashier_init(address token_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlExt_init_unchained();
        __Blocklistable_init_unchained(OWNER_ROLE);
        __Pausable_init_unchained();
        __PausableExt_init_unchained(OWNER_ROLE);
        __Rescuable_init_unchained(OWNER_ROLE);

        __PixCashier_init_unchained(token_);
    }

    function __PixCashier_init_unchained(address token_) internal onlyInitializing {
        if (token_ == address(0)) {
            revert ZeroTokenAddress();
        }

        _token = token_;

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(CASHIER_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, _msgSender());
    }

    /**
     * @dev See {IPixCashier-underlyingToken}.
     */
    function underlyingToken() external view returns (address) {
        return _token;
    }

    /**
     * @dev See {IPixCashier-cashOutBalanceOf}.
     */
    function cashOutBalanceOf(address account) external view returns (uint256) {
        return _cashOutBalances[account];
    }

    /**
     * @dev See {IPixCashier-pendingCashOutCounter}.
     */
    function pendingCashOutCounter() external view returns (uint256) {
        return _pendingCashOutTxIds.length();
    }

    /**
     * @dev See {IPixCashier-processedCashOutCounter}.
     */
    function processedCashOutCounter() external view returns (uint256) {
        return _processedCashOutCounter;
    }

    /**
     * See {IPixCashier-getPendingCashOutTxIds}.
     */
    function getPendingCashOutTxIds(uint256 index, uint256 limit) external view returns (bytes32[] memory txIds) {
        uint256 len = _pendingCashOutTxIds.length();
        if (len <= index || limit == 0) {
            txIds = new bytes32[](0);
        } else {
            len -= index;
            if (len > limit) {
                len = limit;
            }
            txIds = new bytes32[](len);
            for (uint256 i = 0; i < len; i++) {
                txIds[i] = _pendingCashOutTxIds.at(index);
                index++;
            }
        }
    }

    /**
     * @dev See {IPixCashier-getCashIn}.
     */
    function getCashIn(bytes32 txId) external view returns (CashInOperation memory) {
        return _cashIns[txId];
    }

    /**
     * @dev See {IPixCashier-getCashIns}.
     */
    function getCashIns(bytes32[] memory txIds) external view returns (CashInOperation[] memory cashIns) {
        uint256 len = txIds.length;
        cashIns = new CashInOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashIns[i] = _cashIns[txIds[i]];
        }
    }

    /**
     * @dev See {IPixCashier-getCashInBatch}.
     */
    function getCashInBatch(bytes32 batchId) external view returns (CashInBatchOperation memory) {
        return _cashInBatches[batchId];
    }

    /**
     * @dev See {IPixCashier-getCashInBatches}.
     */
    function getCashInBatches(
        bytes32[] memory batchIds
    ) external view returns (CashInBatchOperation[] memory cashInBatches) {
        uint256 len = batchIds.length;
        cashInBatches = new CashInBatchOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashInBatches[i] = _cashInBatches[batchIds[i]];
        }
    }

    /**
     * @dev See {IPixCashier-getCashOut}.
     */
    function getCashOut(bytes32 txIds) external view returns (CashOut memory) {
        return _cashOuts[txIds];
    }

    /**
     * @dev See {IPixCashier-getCashOuts}.
     */
    function getCashOuts(bytes32[] memory txIds) external view returns (CashOut[] memory cashOuts) {
        uint256 len = txIds.length;
        cashOuts = new CashOut[](len);
        for (uint256 i = 0; i < len; i++) {
            cashOuts[i] = _cashOuts[txIds[i]];
        }
    }

    /**
     * @dev See {IPixCashier-cashIn}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `account`, `amount`, and `txId` values must not be zero.
     * - The cash-in operation with the provided `txId` must not be already executed.
     */
    function cashIn(
        address account,
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _cashIn(account, amount, txId, CashInExecutionPolicy.Revert);
    }

    /**
     * @dev See {IPixCashier-cashInBatch}.
     *
     * Requirements
     *
     * - The length of each passed array must be equal.
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `account`, `amount`, and `txId` values must not be zero.
     * - The provided `accounts`, `amounts`, `txIds` arrays must not be empty and must have the same length.
     * - The provided `batchId` must not be zero
     * - The cash-in batch operation with the provided `batchId` must not be already executed.
     * - Each cash-in operation with the provided identifier from the `txIds` array must not be already executed.
     */
    function cashInBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        bytes32[] memory txIds,
        bytes32 batchId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        if (accounts.length == 0 || accounts.length != amounts.length || accounts.length != txIds.length) {
            revert InvalidBatchArrays();
        }
        if (_cashInBatches[batchId].status == CashInBatchStatus.Executed) {
            revert CashInBatchAlreadyExecuted(batchId);
        }
        if (batchId == 0) {
            revert ZeroBatchId();
        }

        CashInExecutionResult[] memory executionResults = new CashInExecutionResult[](txIds.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            executionResults[i] = _cashIn(accounts[i], amounts[i], txIds[i], CashInExecutionPolicy.Skip);
        }

        _cashInBatches[batchId].status = CashInBatchStatus.Executed;

        emit CashInBatch(batchId, txIds, executionResults);
    }

    /**
     * @dev See {IPixCashier-requestCashOutFrom}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The `account` must not be blocklisted.
     * - The `account`, `amount`, and `txId` values must not be zero.
     * - The cash-out operation with the provided `txId` must not be already pending.
     */
    function requestCashOutFrom(
        address account,
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _requestCashOut(_msgSender(), account, amount, txId);
    }

    /**
     * @dev See {IPixCashier-requestCashOutFromBatch}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - Each `account` in the provided array must not be blocklisted.
     * - Each `account`, `amount`, and `txId` values in the provided arrays must not be zero.
     * - Each cash-out operation with the provided `txId` in the array must not be already pending.
     */
    function requestCashOutFromBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        bytes32[] memory txIds
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        if (accounts.length != amounts.length || accounts.length != txIds.length) {
            revert InvalidBatchArrays();
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            _requestCashOut(_msgSender(), accounts[i], amounts[i], txIds[i]);
        }
    }

    /**
     * @dev See {IPixCashier-confirmCashOut}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `txId` value must not be zero.
     * - The cash-out operation corresponded the provided `txId` value must have the pending status.
     */
    function confirmCashOut(bytes32 txId) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _processCashOut(txId, CashOutStatus.Confirmed);
    }

    /**
     * @dev See {IPixCashier-confirmCashOutBatch}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The input `txIds` array must not be empty.
     * - All the values in the input `txIds` array must not be zero.
     * - All the cash-out operations corresponded the values in the input `txIds` array must have the pending status.
     */
    function confirmCashOutBatch(bytes32[] memory txIds) external whenNotPaused onlyRole(CASHIER_ROLE) {
        uint256 len = txIds.length;
        if (len == 0) {
            revert EmptyTransactionIdsArray();
        }

        for (uint256 i = 0; i < len; i++) {
            _processCashOut(txIds[i], CashOutStatus.Confirmed);
        }
    }

    /**
     * @dev See {IPixCashier-reverseCashOut}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `txId` value must not be zero.
     * - The cash-out operation corresponded the provided `txId` value must have the pending status.
     */
    function reverseCashOut(bytes32 txId) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _processCashOut(txId, CashOutStatus.Reversed);
    }

    /**
     * @dev See {IPixCashier-reverseCashOutBatch}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The input `txIds` array must not be empty.
     * - All the values in the input `txIds` array must not be zero.
     * - All the cash-out operations corresponded the values in the input `txIds` array must have the pending status.
     */
    function reverseCashOutBatch(bytes32[] memory txIds) external whenNotPaused onlyRole(CASHIER_ROLE) {
        uint256 len = txIds.length;
        if (len == 0) {
            revert EmptyTransactionIdsArray();
        }

        for (uint256 i = 0; i < len; i++) {
            _processCashOut(txIds[i], CashOutStatus.Reversed);
        }
    }

    /**
     * @dev See {PixCashier-cashIn}.
     */
    function _cashIn(
        address account,
        uint256 amount,
        bytes32 txId,
        CashInExecutionPolicy policy
    ) internal returns (CashInExecutionResult){
        if (account == address(0)) {
            revert ZeroAccount();
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (txId == 0) {
            revert ZeroTxId();
        }
        if (isBlocklisted(account)) {
            revert BlocklistedAccount(account);
        }

        if (_cashIns[txId].status != CashInStatus.Nonexistent) {
            if (policy == CashInExecutionPolicy.Skip) {
                return CashInExecutionResult.AlreadyExecuted;
            } else {
                revert CashInAlreadyExecuted(txId);
            }
        }

        _cashIns[txId] = CashInOperation({
            status: CashInStatus.Executed,
            account: account,
            amount: amount
        });

        emit CashIn(account, amount, txId);

        if (!IERC20Mintable(_token).mint(account, amount)) {
            revert TokenMintingFailure();
        }

        return CashInExecutionResult.Success;
    }

    /**
     * @dev See {PixCashier-requestCashOut}.
     */
    function _requestCashOut(
        address sender,
        address account,
        uint256 amount,
        bytes32 txId
    ) internal {
        if (account == address(0)) {
            revert ZeroAccount();
        }
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (txId == 0) {
            revert ZeroTxId();
        }
        if (isBlocklisted(account)) {
            revert BlocklistedAccount(account);
        }

        CashOut storage operation = _cashOuts[txId];
        CashOutStatus status = operation.status;
        if (status == CashOutStatus.Pending || status == CashOutStatus.Confirmed) {
            revert InappropriateCashOutStatus(txId, status);
        } else if (status == CashOutStatus.Reversed && operation.account != account) {
            revert InappropriateCashOutAccount(txId, operation.account);
        }

        operation.account = account;
        operation.amount = amount;
        operation.status = CashOutStatus.Pending;

        uint256 newCashOutBalance = _cashOutBalances[account] + amount;
        _cashOutBalances[account] = newCashOutBalance;
        _pendingCashOutTxIds.add(txId);

        emit RequestCashOut(
            account,
            amount,
            newCashOutBalance,
            txId,
            sender
        );

        IERC20Upgradeable(_token).safeTransferFrom(
            account,
            address(this),
            amount
        );
    }

    /**
     * @dev See {PixCashier-confirmCashOut} and {PixCashier-reverseCashOut}.
     */
    function _processCashOut(bytes32 txId, CashOutStatus targetStatus) internal {
        if (txId == 0) {
            revert ZeroTxId();
        }

        CashOut storage operation = _cashOuts[txId];
        CashOutStatus status = operation.status;
        if (status != CashOutStatus.Pending) {
            revert InappropriateCashOutStatus(txId, status);
        }

        address account = operation.account;
        uint256 amount = operation.amount;
        uint256 newCashOutBalance = _cashOutBalances[account] - amount;

        _cashOutBalances[account] = newCashOutBalance;
        _pendingCashOutTxIds.remove(txId);
        _processedCashOutCounter += 1;

        operation.status = targetStatus;

        if (targetStatus == CashOutStatus.Confirmed) {
            emit ConfirmCashOut(
                account,
                amount,
                newCashOutBalance,
                txId
            );
            IERC20Mintable(_token).burn(amount);
        } else {
            emit ReverseCashOut(
                account,
                amount,
                newCashOutBalance,
                txId
            );
            IERC20Upgradeable(_token).safeTransfer(account, amount);
        }
    }
}
