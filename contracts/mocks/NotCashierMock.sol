// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ICashierTypes } from "../interfaces/ICashierTypes.sol";

/**
 * @title NotCashierShardMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev An implementation of a mock balance freezer shard contract for testing purposes.
 */
contract NotCashierMock is ICashierTypes {
    /**
     * @dev Simulates real CashierShard contract.
     */
    function isRoot() external pure returns(bool) {
        return false;
    }
}
