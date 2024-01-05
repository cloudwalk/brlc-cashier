// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { BlocklistableUpgradeable } from "../../base/BlocklistableUpgradeable.sol";

/**
 * @title BlocklistableUpgradeableMock contract
 * @author CloudWalk Inc.
 * @dev An implementation of the {BlocklistableUpgradeable} contract for test purposes.
 */
contract BlocklistableUpgradeableMock is BlocklistableUpgradeable {
    /// @dev The role of this contract owner.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev Emitted when a test function of the `notBlocklisted` modifier executes successfully.
    event TestNotBlocklistedModifierSucceeded();

    /**
     * @dev The initialize function of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     */
    function initialize() public initializer {
        _setupRole(OWNER_ROLE, _msgSender());
        __Blocklistable_init(OWNER_ROLE);
    }

    /**
     * @dev Needed to check that the initialize function of the ancestor contract
     * has the 'onlyInitializing' modifier.
     */
    function call_parent_initialize() public {
        __Blocklistable_init(OWNER_ROLE);
    }

    /**
     * @dev Needed to check that the unchained initialize function of the ancestor contract
     * has the 'onlyInitializing' modifier.
     */
    function call_parent_initialize_unchained() public {
        __Blocklistable_init_unchained(OWNER_ROLE);
    }

    /**
     * @dev Checks the execution of the {notBlocklisted} modifier.
     * If that modifier executed without reverting emits an event {TestNotBlocklistedModifierSucceeded}.
     */
    function testNotBlocklistedModifier() external notBlocklisted(_msgSender()) {
        emit TestNotBlocklistedModifierSucceeded();
    }
}
