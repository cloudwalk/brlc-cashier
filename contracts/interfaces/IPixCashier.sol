// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title PixCashier types interface
 */
interface IPixCashierTypes {
    /**
     * @dev Possible statuses of a cash-in operation as an enum.
     *
     * The possible values:
     * - Nonexistent - The operation does not exist (the default value).
     * - Executed ---- The operation was executed.
     */
    enum CashInStatus {
        Nonexistent, // 0
        Executed     // 1
    }

    /**
     * @dev Possible statuses of a cash-in batch operation as an enum.
     *
     * The possible values:
     * - Nonexistent - The operation does not exist (the default value).
     * - Executed ---- The operation was executed.
     */
    enum CashInBatchStatus {
        Nonexistent, // 0
        Executed     // 1
    }

    /**
     * @dev Possible result statuses of a cash-in operation as an enum.
     *
     * The possible values:
     * - Success --------- The operation was executed successfully.
     * - AlreadyExecuted - The operation was already executed.
     */
    enum CashInExecutionResult {
        Success,        // 0
        AlreadyExecuted // 1
    }

    /**
     * @dev Possible execution policies of a cash-in operation as an enum.
     *
     * The possible values:
     * - Revert - In case of failure the operation will be reverted.
     * - Skip --- In case of failure the operation will be skipped.
     */
    enum CashInExecutionPolicy {
        Revert, // 0
        Skip    // 1
    }

    /**
     * @dev Possible statuses of a cash-out operation as an enum.
     *
     * The possible values:
     * - Nonexistent - The operation does not exist (the default value).
     * - Pending ----- The status immediately after the operation requesting.
     * - Reversed ---- The operation was reversed.
     * - Confirmed --- The operation was confirmed.
     */
    enum CashOutStatus {
        Nonexistent, // 0
        Pending,     // 1
        Reversed,    // 2
        Confirmed    // 3
    }

    /// @dev Structure with data of a single cash-in operation.
    struct CashInOperation {
        CashInStatus status;  // The status of the cash-in operation according to the {CashInStatus} enum.
        address account;      // The owner of tokens to cash-in.
        uint256 amount;       // The amount of tokens to cash-in.
    }

    /// @dev Structure with data of a batch cash-in operation.
    struct CashInBatchOperation {
        CashInBatchStatus status;  // The status of the cash-in batch operation according to the {CashInBatchStatus}.
    }

    /// @dev Structure with data of a single cash-in operation.
    struct CashOut {
        address account;      // The owner of tokens to cash-out.
        uint256 amount;       // The amount of tokens to cash-out.
        CashOutStatus status; // The status of the cash-out operation according to the {CashOutStatus} enum.
    }
}

/**
 * @title PixCashier interface
 * @dev The interface of the wrapper contract for PIX cash-in and cash-out operations.
 */
interface IPixCashier is IPixCashierTypes {
    /// @dev Emitted when a new cash-in operation is executed.
    event CashIn(
        address indexed account, // The account that receives tokens.
        uint256 amount,          // The amount of tokens to receive.
        bytes32 indexed txId     // The off-chain transaction identifier.
    );

    /// @dev Emitted when a new batch of cash-in operations is executed.
    event CashInBatch(
        bytes32 indexed batchId,                 // The off-chain batch identifier.
        bytes32[] txIds,                         // The array of off-chain identifiers for each operation in the batch.
        CashInExecutionResult[] executionResults // The array of execution results for each operation in the batch.
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

    /**
     * @dev Returns the address of the underlying token.
     */
    function underlyingToken() external view returns (address);

    /**
     * @dev Returns the data of a single cash-in operation.
     * @param txId The off-chain transaction identifier of the operation.
     */
    function getCashIn(bytes32 txId) external view returns (CashInOperation memory);

    /**
     * @dev Returns the data of multiple cash-in operations.
     * @param txIds The off-chain transaction identifiers of the operations.
     */
    function getCashIns(bytes32[] memory txIds) external view returns (CashInOperation[] memory cashIns);

    /**
     * @dev Returns the data of a cash-in batch operation.
     * @param batchId The off-chain identifier of the cash-in batch operation.
     */
    function getCashInBatch(bytes32 batchId) external view returns (CashInBatchOperation memory);

    /**
     * @dev Returns the data of multiple cash-in batch operations.
     * @param batchIds The off-chain identifiers of the cash-in batch operations.
     */
    function getCashInBatches(
        bytes32[] memory batchIds
    ) external view returns (CashInBatchOperation[] memory cashInBatches);

    /**
     * @dev Returns the pending cash-out balance for an account.
     * @param account The address of the account.
     */
    function cashOutBalanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the pending cash-out operation counter.
     */
    function pendingCashOutCounter() external view returns (uint256);

    /**
     * @dev Returns the processed cash-out operation counter (reversed and confirmed operations included).
     */
    function processedCashOutCounter() external view returns (uint256);

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
     * - 5. If C1 == C2 the result of function calls is consistent. Else repeat the procedure from step 1.
     * @param index The first index in the internal array of pending identifiers to fetch.
     * @param limit The maximum number of returned identifiers.
     * @return txIds The array of requested identifiers.
     */
    function getPendingCashOutTxIds(uint256 index, uint256 limit) external view returns (bytes32[] memory txIds);

    /**
     * @dev Returns the data of a single cash-out operation.
     * @param txId The off-chain transaction identifier of the operation.
     */
    function getCashOut(bytes32 txId) external view returns (CashOut memory);

    /**
     * @dev Returns the data of multiple cash-out operations.
     * @param txIds The off-chain transaction identifiers of the operations.
     */
    function getCashOuts(bytes32[] memory txIds) external view returns (CashOut[] memory cashOuts);

    /**
     * @dev Executes a cash-in operation.
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
    function cashIn(
        address account,
        uint256 amount,
        bytes32 txId
    ) external;

    /**
     * @dev Executes a batch of cash-in operations.
     *
     * This function is expected to be called by a limited number of accounts
     * that are allowed to execute cash-in operations.
     *
     * Emits a {CashInBatch} event.
     * Emits a {CashIn} events.
     *
     * @param accounts The array of the addresses of the tokens recipient.
     * @param amounts The array of the token amounts to be received.
     * @param txIds The array of the off-chain transaction identifiers of the operation.
     * @param batchId The off-chain batch identifier.
     */
    function cashInBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        bytes32[] memory txIds,
        bytes32 batchId
    ) external;

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
    function requestCashOutFrom(
        address account,
        uint256 amount,
        bytes32 txId
    ) external;

    /**
     * @dev Initiates a batch of cash-out operations from some other accounts.
     *
     * Transfers tokens from the accounts to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits {CashOut} events.
     *
     * @param accounts The array of accounts on that behalf the operation is made.
     * @param amounts The array of amounts of tokens to be cash-outed.
     * @param txIds The array of off-chain transaction identifiers of the operation.
     */
    function requestCashOutFromBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        bytes32[] memory txIds
    ) external;

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
     * @dev Confirms multiple cash-out operations.
     *
     * Burns tokens previously transferred to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {CashOutConfirm} event for each operation.
     *
     * @param txIds The off-chain transaction identifiers of the operations.
     */
    function confirmCashOutBatch(bytes32[] memory txIds) external;

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
     * @dev Reverts multiple cash-out operation.
     *
     * Transfers tokens back from the contract to the accounts that requested the operations.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {CashOutReverse} event for each operation.
     *
     * @param txIds The off-chain transaction identifiers of the operations.
     */
    function reverseCashOutBatch(bytes32[] memory txIds) external;
}
