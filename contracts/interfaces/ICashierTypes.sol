// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ICashierTypes interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Defines the types used in the cashier contract.
 */
interface ICashierTypes {
    /**
     * @dev Possible statuses of a cash-in operation as an enum.
     *
     * The possible values:
     * - Nonexistent = 0 ------ The operation does not exist (the default value).
     * - Executed = 1 --------- The operation was executed as a common mint.
     * - PremintExecuted = 2 -- The operation was executed as a premint with some predetermined release time.
     */
    enum CashInStatus {
        Nonexistent,
        Executed,
        PremintExecuted
    }

    /**
     * @dev Possible result statuses of a cash-in operation as an enum.
     *
     * The possible values:
     * - Success = 0 -------------- The operation was executed successfully.
     * - AlreadyExecuted = 1 ------ The operation was already executed.
     * - InappropriateStatus = 2 -- The operation has inappropriate status and cannot be modified.
     */
    enum CashInExecutionResult {
        Success,
        AlreadyExecuted,
        InappropriateStatus
    }

    /**
     * @dev Possible execution policies of a cash-in operation as an enum.
     *
     * The possible values:
     * - Revert = 0 -- In case of failure the operation will be reverted.
     * - Skip = 1 ---- In case of failure the operation will be skipped.
     */
    enum CashInExecutionPolicy {
        Revert,
        Skip
    }

    /**
     * @dev Possible statuses of a cash-out operation as an enum.
     *
     * The possible values:
     * - Nonexistent = 0 -- The operation does not exist (the default value).
     * - Pending = 1 ------ The status immediately after the operation requesting.
     * - Reversed = 2 ----- The operation was reversed.
     * - Confirmed = 3 ---- The operation was confirmed.
     * - Internal = 4 ----- The operation executed internally
     * - Forced = 5 ------- The operation was forcibly executed.
     */
    enum CashOutStatus {
        Nonexistent,
        Pending,
        Reversed,
        Confirmed,
        Internal,
        Forced
    }

    /**
     * @dev Indexes of bit flags that are used to process cash-in operations:
     *
     * - SomeHookRegistered = 0 -- The flag that indicates whether a hook function is registered for the operation.
     *
     * Notes:
     * - 1. This enum is not used in the current implementation.
     * - 2. An example of the code to convert a `CashInFlagIndex` value to a bit flag:
     *
     *    ```solidity
     *    uint256 flag = 1 << uint256(CashInFlagIndex.SomeHookRegistered);
     *    ```
     */
    enum CashInFlagIndex {
        SomeHookRegistered
    }

    /**
     * @dev Indexes of bit flags that are used to process cash-out operations:
     *
     * - SomeHookRegistered = 0 -- The flag that indicates whether a hook function is registered for the operation.
     *
     * Note: an example of the code to convert a `CashInFlagIndex` value to a bit flag:
     *
     *    ```solidity
     *    uint256 flag = 1 << uint256(CashOutFlagIndex.SomeHookRegistered);
     *    ```
     */
    enum CashOutFlagIndex {
        SomeHookRegistered
    }

    /// @dev Structure with data of a single cash-in operation.
    struct CashInOperation {
        CashInStatus status; // --- The status of the cash-in operation according to the {CashInStatus} enum.
        address account; // ------- The owner of tokens to cash-in.
        uint64 amount; // --------- The amount of tokens to cash-in.
        uint8 flags; // ----------- The bit field of flags for the operation. See {CashInFlagIndex}.
        // uint16 __reserved; // -- Reserved for future use until the end of the storage slot.
    }

    /// @dev Structure with data of a single cash-out operation.
    struct CashOutOperation {
        CashOutStatus status; // -- The status of the cash-out operation according to the {CashOutStatus} enum.
        address account; // ------- The owner of tokens to cash-out.
        uint64 amount; // --------- The amount of tokens to cash-out.
        uint8 flags; // ----------- The bit field of flags for the operation. See {CashOutFlagIndex}.
        // uint16 __reserved; // -- Reserved for future use until the end of the storage slot.
    }
}
