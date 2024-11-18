// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { UUPSExtUpgradeable } from "../../base/UUPSExtUpgradeable.sol";

/**
 * @title UUPSExtUpgradableMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev An implementation of the {UUPSExtUpgradable} contract for test purposes.
 */
contract UUPSExtUpgradeableMock is UUPSExtUpgradeable {
    /// @dev Emitted when the internal `_validateUpgrade()` function is called with the parameters of the function.
    event MockValidateUpgradeCall(address newImplementation);

    /**
     * @dev Executes further validation steps of the upgrade including authorization and implementation address checks.
     * @param newImplementation The address of the new implementation.
     */
    function _validateUpgrade(address newImplementation) internal virtual override {
        emit MockValidateUpgradeCall(newImplementation);
    }
}
