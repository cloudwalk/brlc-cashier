// SPDX-License-Identifier: MIT

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ICashierShard } from "./interfaces/ICashierShard.sol";
import { ICashierHookableTypes } from "./interfaces/ICashierHookable.sol";

pragma solidity ^0.8.0;

/**
 * @title Cashier storage version 1
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 */
abstract contract CashierStorageV1 {
    /// @dev The address of the underlying token.
    address internal _token;

    /// @dev The array of the underlying shard contracts.
    ICashierShard[] internal _shards;

    /// @dev The mapping of a pending cash-out balance for a given account.
    mapping(address => uint256) internal _cashOutBalances;

    /// @dev The set of off-chain transaction identifiers that correspond the pending cash-out operations.
    EnumerableSet.Bytes32Set internal _pendingCashOutTxIds;
}

/**
 * @title Cashier storage version 2
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 */
abstract contract CashierStorageV2 is ICashierHookableTypes {
    /// @dev The mapping of the hook configurations for the cash-in operations. Is not used in the current version.
    mapping(bytes32 => HookConfig) internal _cashInHookConfigs;

    /// @dev The mapping of the hook configurations for the cash-out operations.
    mapping(bytes32 => HookConfig) internal _cashOutHookConfigs;
}

/**
 * @title Cashier storage
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Contains storage variables of the {Cashier} contract.
 *
 * When we need to add new storage variables, we create a new version of CashierStorage
 * e.g. CashierStorage<versionNumber>, so finally it would look like
 * "contract CashierStorage is CashierStorageV1, CashierStorageV2".
 */
abstract contract CashierStorage is CashierStorageV1, CashierStorageV2 {
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[43] private __gap;
}
