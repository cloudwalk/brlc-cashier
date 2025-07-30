// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ICashierHookableTypes interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Defines the types used in the cashier hookable contract.
 */
interface ICashierHookableTypes {
    /**
     * @dev Possible indexes of hooks that are used to apply additional external actions during some operation steps.
     *
     * Those actions are triggered through the hook function that are implemented in external contracts and
     * called by the Cashier contract at concrete moments.
     * The index of the hook is passed to the hook function to indicate when it was called.
     *
     * The possible values:
     *
     * - CashInCommonBefore = 0 --------- Called before the token transfer during a common cash-in operation.
     * - CashInCommonAfter = 1 ---------- Called after the token transfer during a common cash-in operation.
     * - CashInPremintBefore = 2 -------- Called before the token transfer during a premint cash-in operation.
     * - CashInPremintAfter = 3 --------- Called after the token transfer during a premint cash-in operation.
     * - Reserved1 = 4 ------------------ Reserved for the future.
     * - Reserved2 = 5 ------------------ Reserved for the future.
     * - CashOutRequestBefore = 6 ------- Called before the token transfer during a cash-out request operation.
     * - CashOutRequestAfter = 7 -------- Called after the token transfer during a cash-out request operation.
     * - CashOutConfirmationBefore = 8 -- Called before the token transfer during a cash-out confirmation operation.
     * - CashOutConfirmationAfter = 9 --- Called after the token transfer during a cash-out confirmation operation.
     * - CashOutReversalBefore = 10 ----- Called before the token transfer during a cash-out reversal operation.
     * - CashOutReversalAfter = 11 ------ Called after the token transfer during a cash-out reversal operation.
     *
     * Notes:
     *
     * - 1. Hooks with indexes from 0 to 5 including are not used in the current implementation.
     * - 2. The hook with index `CashOutRequestAfter` is not called during internal cash-out operations.
     * - 3. An example of the code to convert a `HookIndex` value to bit flags:
     *
     *    ```solidity
     *    uint256 flag1 = 1 << uint256(HookIndex.CashOutRequestBefore);
     *    uint256 flag2 = 1 << uint256(HookIndex.CashOutConfirmationAfter);
     *    uint256 flag3 = 1 << uint256(HookIndex.CashOutReversalAfter);
     *    uint256 flags = flag1 + flag2 + flag3;
     *    ```
     */
    enum HookIndex {
        CashInCommonBefore,
        CashInCommonAfter,
        CashInPremintBefore,
        CashInPremintAfter,
        Reserved1,
        Reserved2,
        CashOutRequestBefore,
        CashOutRequestAfter,
        CashOutConfirmationBefore,
        CashOutConfirmationAfter,
        CashOutReversalBefore,
        CashOutReversalAfter
    }

    /**
     * @dev The hook configuration for a concrete cashier operation.
     *
     * The fields:
     *
     * - callableContract -- The address of the contract that implements the hook function.
     * - hookFlags --------- The bit flags that define when the hook function should be called.
     */
    struct HookConfig {
        // Slot 1
        address callableContract;
        uint32 hookFlags;
        // uint64 __reserved; // Reserved until the end of the storage slot
    }
}

/**
 * @title ICashierHookable interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The interface of an addition to the cashier contract that allows to call a hook functions.
 */
interface ICashierHookable is ICashierHookableTypes {
    // ------------------ Events ---------------------------------- //

    /**
     * @dev Emitted when the hook configuration is changed for a cash-out operation.
     * @param txId The unique off-chain transaction identifier of the related operation.
     * @param newCallableContract The new address of the callable contract on the hook configuration.
     * @param oldCallableContract The old address of the callable contract on the hook configuration.
     * @param newHookFlags The new bit flags of the hook configuration.
     * @param oldHookFlags The old bit flags of the hook configuration.
     */
    event CashOutHooksConfigured(
        bytes32 indexed txId, // Tools: prevent Prettier one-liner
        address newCallableContract,
        address oldCallableContract,
        uint256 newHookFlags,
        uint256 oldHookFlags
    );

    /**
     * @dev Emitted when a hook function is called.
     * @param txId The unique off-chain transaction identifier of the related operation.
     * @param hookIndex The index of the related hook.
     * @param callableContract The address of the contract that implements the hook function.
     */
    event HookInvoked(
        bytes32 indexed txId, // Tools: prevent Prettier one-liner
        uint256 indexed hookIndex,
        address callableContract
    );

    // ------------------ Transactional functions ----------------- //

    /**
     * @dev Configures the hook logic for a cash-out operation.
     * @param txId The unique off-chain transaction identifier of the related operation.
     * @param newCallableContract The address of the contract that implements the hook function to be called.
     * @param newHookFlags The bit flags that define when the hook function should be called.
     *        See notes for the {HookIndex} enumeration.
     */
    function configureCashOutHooks(bytes32 txId, address newCallableContract, uint256 newHookFlags) external;

    /**
     * @dev Returns the current hook configuration for a cash-out operation.
     * @param txId The unique off-chain transaction identifier of the related operation.
     * @return The hook configuration structure.
     */
    function getCashOutHookConfig(bytes32 txId) external view returns (HookConfig memory);
}
