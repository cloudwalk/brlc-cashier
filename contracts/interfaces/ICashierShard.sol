// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ICashierTypes } from "./ICashierTypes.sol";

/**
 * @title ICashierShardErrors interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Defines the custom errors used in the cashier shard contract.
 */
interface ICashierShardErrors {
    /// @dev Thrown if the contract is not a shard contract.
    error CashierShard_ContractNotShard();

    /// @dev Thrown if the caller is not an admin.
    error CashierShard_Unauthorized();
}

/**
 * @title ICashierShardPrimary interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The primary part of the cashier shard contract interface.
 */
interface ICashierShardPrimary is ICashierTypes {
    /**
     * @dev Possible function errors of the shard contract.
     *
     * The values:
     * - None = 0 ------------------------- There is no error. The function was executed successfully.
     * - CashInAlreadyExecuted = 1 -------- The cash-in operation has already been executed.
     * - InappropriateCashInStatus = 2 ---- The cash-in operation status is inappropriate.
     * - InappropriateCashOutStatus = 3 --- The cash-out operation status is inappropriate.
     * - InappropriateCashOutAccount = 4 -- The cash-out operation account is inappropriate.
     */
    enum Error {
        None,
        CashInAlreadyExecuted,
        InappropriateCashInStatus,
        InappropriateCashOutStatus,
        InappropriateCashOutAccount
    }

    // ------------------ Functions ------------------------------- //

    /**
     * @dev Registers a cash-in operation.
     * @param account The address of the account.
     * @param amount The amount of the cash-in operation.
     * @param txId The off-chain identifier of the cash-in operation.
     * @param status The status of the operation according to the {CashInStatus} enum.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     */
    function registerCashIn(
        address account,
        uint256 amount,
        bytes32 txId,
        CashInStatus status
    ) external returns (uint256 err);

    /**
     * @dev Revokes a cash-in operation.
     * @param txId The off-chain identifier of the cash-in operation.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     * @return account The address of the account of the cash-in operation.
     * @return amount The amount of the cash-in operation.
     */
    function revokeCashIn(bytes32 txId) external returns (uint256 err, address account, uint256 amount);

    /**
     * @dev Registers a cash-out operation.
     * @param account The address of the account.
     * @param amount The amount of the cash-out operation.
     * @param txId The off-chain identifier of the cash-out operation.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     * @return flags The flags field of the stored cash-out operation structure.
     */
    function registerCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external returns (uint256 err, uint256 flags);

    /**
     * @dev Registers an internal cash-out operation.
     * @param account The address of the account.
     * @param amount The amount of the cash-out operation.
     * @param txId The off-chain identifier of the cash-out operation.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     * @return flags The flags field of the stored cash-out operation structure.
     */
    function registerInternalCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external returns (uint256 err, uint256 flags);

    /**
     * @dev Registers a forced cash-out operation.
     * @param account The address of the account.
     * @param amount The amount of the cash-out operation.
     * @param txId The off-chain identifier of the cash-out operation.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     * @return flags The flags field of the stored cash-out operation structure.
     */
    function registerForcedCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external returns (uint256 err, uint256 flags);

    /**
     * @dev Processes a cash-out operation.
     * @param txId The off-chain identifier of the cash-out operation.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     * @return account The address of the account of the cash-out operation.
     * @return amount The amount of the cash-out operation.
     * @return flags The flags field of the stored cash-out operation structure.
     */
    function processCashOut(
        bytes32 txId,
        CashOutStatus status
    ) external returns (uint256 err, address account, uint256 amount, uint256 flags);

    /**
     * @dev Sets a specific bit in the flags of a cash-out operation.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param bit The bit to set.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     */
    function setBitInCashOutFlags(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint8 bit
    ) external returns (uint256 err);

    /**
     * @dev Resets a specific bit in the flags of a cash-out operation.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param bit The bit to reset.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     */
    function resetBitInCashOutFlags(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint8 bit
    ) external returns (uint256 err);

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
     * @dev Determines whether the contract is the cashier shard contract.
     */
    function isCashierShard() external pure;
}

/**
 * @title ICashierShardConfiguration interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The configuration part of the cashier shard contract interface.
 */
interface ICashierShardConfiguration {
    /**
     * @dev Sets the admin status of an account.
     * @param account The address of the account to configure.
     * @param status The admin status of the account.
     */
    function setAdmin(address account, bool status) external;

    /**
     * @dev Checks if an account is an admin.
     * @param account The address of the account to check.
     * @return isAdmin The admin status of the account.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * @dev Upgrades the implementation of the contract.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeTo(address newImplementation) external;
}

/**
 * @title ICashierShard interface
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The full interface of the cashier shard contract.
 */
interface ICashierShard is
    ICashierShardErrors, // Tools: this comment prevents Prettier from formatting into a single line.
    ICashierShardPrimary,
    ICashierShardConfiguration
{}
