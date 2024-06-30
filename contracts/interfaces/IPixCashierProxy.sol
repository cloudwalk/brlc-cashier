// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IPixCashierTypes } from "./IPixCashierTypes.sol";

/**
 * @title PixCashier interface
 * @dev The interface of the wrapper contract for PIX cash-in and cash-out operations.
 */
interface IPixCashierProxy is IPixCashierTypes {
    // ------------------ Events ---------------------------------- //

    /// @dev Emitted when a new cash-in operation is executed.
    event CashIn(
        address indexed account, // The account that receives tokens.
        uint256 amount,          // The amount of tokens to receive.
        bytes32 indexed txId     // The off-chain transaction identifier.
    );

    /// @dev Emitted when a cash-in premint operation is executed or changed.
    event CashInPremint(
        address indexed account, // The account that will receive the preminted tokens.
        uint256 newAmount,       // The new amount of preminted tokens.
        uint256 oldAmount,       // The old amount of preminted tokens.
        bytes32 indexed txId,    // The off-chain transaction identifier for the operation.
        uint256 releaseTime      // The timestamp when the preminted tokens will become available for usage.
    );

    /// @dev Emitted when a new cash-out operation is initiated.
    event RequestCashOut(
        address indexed account, // The account that owns the tokens to cash-out.
        uint256 amount,          // The amount of tokens to cash-out.
        uint256 balance,         // The new pending cash-out balance of the account.
        bytes32 indexed txId,    // The off-chain transaction identifier.
        address indexed sender   // The account that initiated the cash-out.
    );

    /// @dev Emitted when a cash-out operation is confirmed.
    event ConfirmCashOut(
        address indexed account, // The account that owns the tokens to cash-out.
        uint256 amount,          // The amount of tokens to cash-out.
        uint256 balance,         // The new pending cash-out balance of the account.
        bytes32 indexed txId     // The off-chain transaction identifier.
    );

    /// @dev Emitted when a cash-out operation is reversed.
    event ReverseCashOut(
        address indexed account, // The account that owns the tokens to cash-out.
        uint256 amount,          // The amount of tokens to cash-out.
        uint256 balance,         // The new pending cash-out balance of the account.
        bytes32 indexed txId     // The off-chain transaction identifier.
    );

    // ------------------ Functions ------------------------------- //

    /**
     * @dev Executes a cash-in operation as a common mint.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cash-in operations.
     *
     * Emits a {CashIn} event.
     *
     * @param account The address of the tokens recipient.
     * @param amount The amount of tokens to be received.
     * @param txId The off-chain transaction identifier of the operation.
     */
    function cashIn(address account, uint256 amount, bytes32 txId) external;

    /**
     * @dev Executes a cash-in operation as a premint with some predetermined release time.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cash-in operations.
     *
     * Emits a {CashInPremint} event.
     *
     * @param account The address of the tokens recipient.
     * @param amount The amount of tokens to be received.
     * @param txId The off-chain transaction identifier of the operation.
     * @param releaseTime The timestamp when the minted tokens will become available for usage.
     */
    function cashInPremint(
        address account,
        uint256 amount,
        bytes32 txId,
        uint256 releaseTime
    ) external;

    /**
     * @dev Revokes the existing premint that has not yet been released.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cash-in operations.
     *
     * Emits a {CashInPremint} event.
     *
     * @param txId The off-chain transaction identifier of the operation.
     * @param releaseTime The timestamp of the premint that will be revoked.
     */
    function cashInPremintRevoke(
        bytes32 txId,
        uint256 releaseTime
    ) external;

    /**
     * @dev Reschedules original cash-in premint release to a new target release.
     *
     * @param originalRelease The timestamp of the original premint release to be rescheduled.
     * @param targetRelease The new timestamp of the premint release to set during the rescheduling.
     */
    function reschedulePremintRelease(uint256 originalRelease, uint256 targetRelease) external;

    /**
     * @dev Initiates a cash-out operation from some other account.
     *
     * Transfers tokens from the account to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {CashOut} event.
     *
     * @param account The account on that behalf the operation is made.
     * @param amount The amount of tokens to be cash-outed.
     * @param txId The off-chain transaction identifier of the operation.
     */
    function requestCashOutFrom(address account, uint256 amount, bytes32 txId) external;

    /**
     * @dev Confirms a single cash-out operation.
     *
     * Burns tokens previously transferred to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {CashOutConfirm} event for the operation.
     *
     * @param txId The off-chain transaction identifier of the operation.
     */
    function confirmCashOut(bytes32 txId) external;

    /**
     * @dev Reverts a single cash-out operation.
     *
     * Transfers tokens back from the contract to the account that requested the operation.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {CashOutReverse} event for the operation.
     *
     * @param txId The off-chain transaction identifier of the operation.
     */
    function reverseCashOut(bytes32 txId) external;

    /**
     * @dev Adds a new shards to the proxy.
     * @param shards The array of shard addresses to add.
     */
    function addShards(address[] memory shards) external;

    // ------------------ View functions -------------------------- //

    /**
     * @dev Returns the data of a single cash-in operation.
     * @param txId The off-chain transaction identifier of the operation.
     * @return operation The data of the cash-in operation in the form of a structure.
     */
    function getCashIn(bytes32 txId) external view returns (CashInOperation memory operation);

    /**
     * @dev Returns the data of multiple cash-in operations.
     * @param txIds The off-chain transaction identifiers of the operations.
     * @return operations The data of the cash-in operations in the form of a structure.
     */
    function getCashIns(bytes32[] memory txIds) external view returns (CashInOperation[] memory operations);

    /**
     * @dev Returns the data of a single cash-out operation.
     * @param txId The off-chain transaction identifier of the operation.
     * @return operation The data of the cash-out operation in the form of a structure.
     */
    function getCashOut(bytes32 txId) external view returns (CashOutOperation memory operation);

    /**
     * @dev Returns the data of multiple cash-out operations.
     * @param txIds The off-chain transaction identifiers of the operations.
     * @return operations The data of the cash-out operations in the form of a structure.
     */
    function getCashOuts(bytes32[] memory txIds) external view returns (CashOutOperation[] memory operations);

    /**
     * @dev Returns the off-chain transaction identifiers of pending cash-out operations.
     *
     * No guarantees are made on the ordering of the identifiers in the returned array.
     * When you can't prevent confirming and reversing of cash-out operations during calling this function several
     * times to sequentially read of all available identifiers the following procedure is recommended:
     *
     * - 1. Call the `processedCashOutCounter()` function and remember the returned value as C1.
     * - 2. Call this function several times with needed values of `index` and `limit` like (0,5), (5,5), (10,5), ...
     * - 3. Execute step 2 until the length of the returned array becomes less than the `limit` value.
     * - 4. Call the `processedCashOutCounter()` function and remember the returned value as C2.
     * - 5. If C1 == C2 the result of function calls is consistent, else repeat the procedure from step 1.
     * @param index The first index in the internal array of pending identifiers to fetch.
     * @param limit The maximum number of returned identifiers.
     * @return txIds The array of requested identifiers.
     */
    function getPendingCashOuts(uint256 index, uint256 limit) external view returns (bytes32[] memory txIds);

    /**
     * @dev Returns the pending cash-out balance for an account.
     * @param account The address of the account to check.
     */
    function cashOutBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the pending cash-out operation counter.
     */
    function pendingCashOutCounter() external view returns (uint256);

    /**
     * @dev Returns the address of the underlying token.
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Returns the number of shards in the proxy.
     */
    function getShardCount() external view returns (uint256);

    /**
     * @dev Returns the shard address by the off-chain transaction identifier.
     * @param txId The off-chain transaction identifier of the operation.
     */
    function getShardByTxId(bytes32 txId) external view returns (address);

    /**
     * @dev Returns the array of shard addresses by the range of indexes.
     * @param startIndex The start index of the range.
     * @param endIndex The end index of the range.
     */
    function getShardRange(uint256 startIndex, uint256 endIndex) external view returns (address[] memory);
}
