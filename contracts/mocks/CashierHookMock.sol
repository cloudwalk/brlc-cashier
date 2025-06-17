// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title CashierHookMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev A simplified version of a cashier hook contract to use in tests for other contracts.
 */
contract CashierHookMock {
    /// @dev A counter of the hook function calls.
    uint256 public hookCallCounter;

    // ------------------ Events ---------------------------------- //

    /// @dev Emitted when the `onCashierHook()` function is called with the parameters of the function.
    event MockCashierHookCalled(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 hookIndex,
        uint256 hookCallCounter
    );

    // ------------------ Transactional functions ----------------- //

    /// @dev Imitates the same-name function of the {ICashierHook} interface.
    function onCashierHook(uint256 hookIndex, bytes32 txId) external {
        hookCallCounter += 1;
        emit MockCashierHookCalled(txId, hookIndex, hookCallCounter);
    }
}
