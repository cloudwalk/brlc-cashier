// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ICashierTypes } from "../interfaces/ICashierTypes.sol";

/**
 * @title CashierShardMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev An implementation of a mock balance freezer shard contract for testing purposes.
 */
contract CashierShardMock is ICashierTypes {
    uint8 public constant REGISTER_OPERATION_UNEXPECTED_ERROR = 0xFF;

    /**
     * @dev Simulates the "registerOperation()" function of the real contract but always returns unexpected error.
     *
     * @param account The address of the account.
     * @param amount The amount of the cash-in operation.
     * @param txId The off-chain identifier of the cash-in operation.
     * @param targetStatus The status of the operation according to the {CashInStatus} enum.
     * @return err The error code if the operation fails, otherwise {Error.None}.
     */
    function registerCashIn(
        address account,
        uint256 amount,
        bytes32 txId,
        CashInStatus targetStatus
    ) external pure returns (uint256 err) {
        account; // Silence the compilation warning about unused variable
        amount; // Silence the compilation warning about unused variable
        txId; // Silence the compilation warning about unused variable
        targetStatus; // Silence the compilation warning about unused variable
        err = REGISTER_OPERATION_UNEXPECTED_ERROR;
    }

    /**
     * @dev Simulates real CashierShard contract.
     */
    function proveCashierShard() external pure {}
}
