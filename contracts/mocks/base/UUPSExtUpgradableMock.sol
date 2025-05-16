// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { UUPSExtUpgradeable } from "../../base/UUPSExtUpgradeable.sol";

/**
 * @title UUPSExtUpgradableMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev An implementation of the {UUPSExtUpgradable} contract for test purposes.
 */
contract UUPSExtUpgradeableMock is UUPSExtUpgradeable {
    // ------------------ Events ---------------------------------- //

    /// @dev Emitted when the internal `_validateUpgrade()` function is called with the parameters of the function.
    event MockValidateUpgradeCall(address newImplementation);

    // ------------------ Initializers ---------------------------- //

    /**
     * @dev The initialize function of the upgradable contract.
     *
     * See details: https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable
     */
    function initialize() public initializer {
        __UUPSExt_init_unchained(); // This is needed only to avoid errors during coverage assessment
    }

    // ------------------ Transactional functions ----------------- //

    /// @dev Calls the parent internal unchained initializing function to verify the 'onlyInitializing' modifier.
    function callParentInitializerUnchained() external {
        __UUPSExt_init_unchained();
    }

    // ------------------ Internal functions ---------------------- //

    /**
     * @dev An implementation of the validateUpgrade function of the UUPSExtUpgradeable contract.
     *
     * Does not execute any validation steps, just emits an event with the parameter of the function.
     *
     * @param newImplementation The address of the new implementation.
     */
    function _validateUpgrade(address newImplementation) internal override {
        emit MockValidateUpgradeCall(newImplementation);
    }
}
