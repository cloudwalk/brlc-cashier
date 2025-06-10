// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ICashierTypes } from "./ICashierTypes.sol";

/**
 * @title ICashierPrimary interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The primary part of the cashier contract interface.
 */
interface ICashierPrimary is ICashierTypes {
    // ------------------ Events ---------------------------------- //

    /**
     * @dev Emitted when a new cash-in operation is executed.
     * @param account The account that receives tokens.
     * @param amount The amount of tokens to receive.
     * @param txId The off-chain transaction identifier.
     */
    event CashIn(
        address indexed account, // Tools: this comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 indexed txId
    );

    /**
     * @dev Emitted when a cash-in premint operation is executed or changed.
     * @param account The account that will receive the preminted tokens.
     * @param newAmount The new amount of preminted tokens.
     * @param oldAmount The old amount of preminted tokens.
     * @param txId The off-chain transaction identifier for the operation.
     * @param releaseTime The timestamp when the preminted tokens will become available for usage.
     */
    event CashInPremint(
        address indexed account,
        uint256 newAmount,
        uint256 oldAmount,
        bytes32 indexed txId,
        uint256 releaseTime
    );

    /**
     * @dev Emitted when a new cash-out operation is initiated.
     * @param account The account that owns the tokens to cash-out.
     * @param amount The amount of tokens to cash-out.
     * @param balance The new pending cash-out balance of the account.
     * @param txId The off-chain transaction identifier.
     * @param sender The account that initiated the cash-out.
     */
    event RequestCashOut(
        address indexed account,
        uint256 amount,
        uint256 balance,
        bytes32 indexed txId,
        address indexed sender
    );

    /**
     * @dev Emitted when a cash-out operation is confirmed.
     * @param account The account that owns the tokens to cash-out.
     * @param amount The amount of tokens to cash-out.
     * @param balance The new pending cash-out balance of the account.
     * @param txId The off-chain transaction identifier.
     */
    event ConfirmCashOut(
        address indexed account, // Tools: this comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 balance,
        bytes32 indexed txId
    );

    /**
     * @dev Emitted when a cash-out operation is reversed.
     * @param account The account that owns the tokens to cash-out.
     * @param amount The amount of tokens to cash-out.
     * @param balance The new pending cash-out balance of the account.
     * @param txId The off-chain transaction identifier.
     */
    event ReverseCashOut(
        address indexed account, // Tools: this comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 balance,
        bytes32 indexed txId
    );

    /**
     * @dev Emitted when an internal cash-out operation is executed.
     * @param from The account that owns the tokens to cash-out.
     * @param txId The off-chain transaction identifier.
     * @param to The account that received the tokens through the internal cash-out.
     * @param amount The amount of tokens to cash-out.
     */
    event InternalCashOut(
        address indexed from, // Tools: this comment prevents Prettier from formatting into a single line.
        bytes32 indexed txId,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted when a forced cash-out operation is initiated.
     * @param account The account that owns the tokens to cash-out.
     * @param txId The off-chain transaction identifier.
     * @param amount The amount of tokens to cash-out.
     */
    event ForcedCashOut(
        address indexed account, // Tools: This comment prevents Prettier from formatting into a single line.
        bytes32 indexed txId,
        uint256 amount
    );

    // ------------------ Transactional functions ----------------- //

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
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function cashIn(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external;

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
     * @param txId The off-chain transaction identifier of the related operation.
     * @param releaseTime The timestamp when the minted tokens will become available for usage.
     */
    function cashInPremint(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
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
     * @param txId The off-chain transaction identifier of the related operation.
     * @param releaseTime The timestamp of the premint that will be revoked.
     */
    function cashInPremintRevoke(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 releaseTime
    ) external;

    /**
     * @dev Reschedules original cash-in premint release to a new target release.
     *
     * @param originalRelease The timestamp of the original premint release to be rescheduled.
     * @param targetRelease The new timestamp of the premint release to set during the rescheduling.
     */
    function reschedulePremintRelease(
        uint256 originalRelease, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 targetRelease
    ) external;

    /**
     * @dev Initiates a cash-out operation from some other account.
     *
     * Transfers tokens from the account to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {RequestCashOut} event.
     *
     * @param account The account on whose behalf the operation is made.
     * @param amount The amount of tokens to be cashed out.
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function requestCashOutFrom(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external;

    /**
     * @dev Confirms a single cash-out operation.
     *
     * Burns tokens previously transferred to the contract.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {ConfirmCashOut} event for the operation.
     *
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function confirmCashOut(bytes32 txId) external;

    /**
     * @dev Reverts a single cash-out operation.
     *
     * Transfers tokens back from the contract to the account that requested the operation.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {ReverseCashOut} event for the operation.
     *
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function reverseCashOut(bytes32 txId) external;

    /**
     * @dev Executes an internal cash-out operation.
     *
     * Transfers tokens from the contract to the recipient account.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits an {InternalCashOut} event.
     *
     * @param from The account that owns the tokens to cash-out.
     * @param to The account that will receive the tokens.
     * @param amount The amount of tokens to be cashed out.
     * @param txId The unique off-chain transaction identifier of the related operation.
     */
    function makeInternalCashOut(
        address from, // Tools: this comment prevents Prettier from formatting into a single line.
        address to,
        uint256 amount,
        bytes32 txId
    ) external;

    /**
     * @dev Initiates a forced cash-out operation.
     *
     * Burns tokens from the account.
     * This function is expected to be called by a limited number of accounts
     * that are allowed to process cash-out operations.
     *
     * Emits a {ForcedCashOut} event.
     *
     * @param account The account on whose behalf the operation is made.
     * @param amount The amount of tokens to be cashed out.
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function forceCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external;

    // ------------------ View functions -------------------------- //

    /**
     * @dev Returns the data of a single cash-in operation.
     * @param txId The off-chain transaction identifier of the related operation.
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
     * @param txId The off-chain transaction identifier of the related operation.
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
    function getPendingCashOutTxIds(uint256 index, uint256 limit) external view returns (bytes32[] memory txIds);

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
}

/**
 * @title ICashierConfiguration interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The configuration part of the cashier contract interface.
 */
interface ICashierConfiguration {
    // ------------------ Events ---------------------------------- //

    /**
     * @dev Emitted when a new shard contract is added to the contract.
     * @param shard The address of the added shard contract.
     */
    event ShardAdded(address shard);

    /**
     * @dev Emitted when an existing shard contract is replaced with a new one.
     * @param newShard The address of the new shard contract.
     * @param oldShard The address of the replaced shard contract.
     */
    event ShardReplaced(address newShard, address oldShard);

    /**
     * @dev Emitted when a shard admin status of an account is configured on all underlying shard contracts.
     * @param account The address of the account to configure.
     * @param status The new admin status of the account.
     */
    event ShardAdminConfigured(address account, bool status);

    // ------------------ Transactional functions ----------------- //

    /**
     * @dev Sets the shards that are allowed to process cash-out operations.
     * @param shards The array of shard addresses to add.
     */
    function addShards(address[] memory shards) external;

    /**
     * @dev Replaces the existing shards with a new set of shards.
     * @param fromIndex The index in the internal array to start replacing from.
     * @param shards The array of shard addresses to replace with.
     */
    function replaceShards(uint256 fromIndex, address[] memory shards) external;

    /**
     * @dev Configures the shard admin status of an account.
     * @param account The address of the account to configure.
     * @param status The new admin status of the account.
     */
    function configureShardAdmin(address account, bool status) external;

    /**
     * @dev Returns the number of shards in the proxy.
     */
    function getShardCount() external view returns (uint256);

    /**
     * @dev Returns the shard address by the off-chain transaction identifier.
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function getShardByTxId(bytes32 txId) external view returns (address);

    /**
     * @dev Returns the shard address by the start index in the internal array.
     * @param index The start index of the shard in the internal array.
     * @param limit The maximum number of returned shards.
     */
    function getShardRange(uint256 index, uint256 limit) external view returns (address[] memory);
}

/**
 * @title ICashierErrors interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Defines the custom errors used in the cashier contract.
 */
interface ICashierErrors {
    /// @dev Thrown if the provided account address is zero.
    error Cashier_AccountAddressZero();

    /// @dev Thrown if the provided amount exceeds the maximum allowed value.
    error Cashier_AmountExcess();

    /// @dev Thrown if the provided amount is zero.
    error Cashier_AmountZero();

    /// @dev Thrown if the cash-in operation with the provided txId is already executed.
    error Cashier_CashInAlreadyExecuted();

    /// @dev Thrown if the cash-in operation with the provided txId has an inappropriate status.
    error Cashier_CashInStatusInappropriate();

    /// @dev Thrown if the cash-out operation with the provided txId has an inappropriate status.
    error Cashier_CashOutStatusInappropriate();

    /// @dev Thrown if the contract is not a cashier shard contract.
    error Cashier_ContractNotShard();

    /// @dev The provided address of the callable contract with the hook function is non-zero but must be.
    error Cashier_HookCallableContractAddressNonZero();

    /// @dev The provided address of the callable contract with the hook function is zero but must not be.
    error Cashier_HookCallableContractAddressZero();

    /// @dev The same hook flags for an operation are already configured.
    error Cashier_HookFlagsAlreadyRegistered();

    /// @dev The provided bit flags to configure the hook logic are invalid.
    error Cashier_HookFlagsInvalid();

    /// @dev Thrown if the contract is not a cashier root contract.
    error Cashier_ImplementationAddressInvalid();

    /// @dev Thrown if the provided release time for the premint operation is inappropriate.
    error Cashier_PremintReleaseTimeInappropriate();

    /// @dev Thrown if the provided shard address is not a contract.
    error Cashier_ShardAddressNotContract();

    /// @dev Thrown if the provided shard address is zero.
    error Cashier_ShardAddressZero();

    /// @dev Thrown if the maximum number of shards is exceeded.
    error Cashier_ShardCountExcess();

    /**
     * @dev Thrown if the shard contract returns an unexpected error.
     * @param err The error code returned by the shard contract.
     */
    error Cashier_ShardErrorUnexpected(uint256 err);

    /// @dev Thrown if the number of shard contracts to replace is greater than expected.
    error Cashier_ShardReplacementCountExcess();

    /// @dev Thrown if the provided token address is zero.
    error Cashier_TokenAddressZero();

    /// @dev Thrown if the minting of tokens failed during a cash-in operation.
    error Cashier_TokenMintingFailure();

    /// @dev Thrown if the provided off-chain transaction identifier is zero.
    error Cashier_TxIdZero();
}

/**
 * @title ICashier interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The full interface of the cashier contract.
 */
interface ICashier is ICashierPrimary, ICashierConfiguration, ICashierErrors {
    /**
     * @dev Proves that the contract is the cashier root contract.
     */
    function proveCashierRoot() external pure;
}
