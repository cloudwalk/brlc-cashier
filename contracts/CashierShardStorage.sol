// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ICashierTypes } from "./interfaces/ICashierTypes.sol";

/**
 * @title CashierShard storage version 1
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 */
abstract contract CashierShardStorageV1 is ICashierTypes {
    /// @dev The mapping of a cash-in operation structure for a given off-chain transaction identifier.
    mapping(bytes32 => CashInOperation) internal _cashInOperations;

    /// @dev The mapping of a cash-out operation structure for a given off-chain transaction identifier.
    mapping(bytes32 => CashOutOperation) internal _cashOutOperations;
}

/**
 * @title CashierShard storage version 2
 */
abstract contract CashierShardStorageV2 is ICashierTypes {
    /// @dev The mapping of an account to its admin status (True if admin, False otherwise).
    mapping(address => bool) internal _admins;
}

/**
 * @title CashierShard storage
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Contains storage variables of the {CashierShard} contract.
 *
 * When we need to add new storage variables, we create a new version of CashierShardStorage
 * e.g. CashierShardStorage<versionNumber>, so finally it would look like
 * "contract CashierShardStorage is CashierShardStorageV1, CashierShardStorageV2".
 */
abstract contract CashierShardStorage is CashierShardStorageV1, CashierShardStorageV2 {
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[47] private __gap;
}
