// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title UUPSExtUpgradeable base contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Extends the OpenZeppelin's {UUPSUpgradeable} contract by adding additional checks for
 * the new implementation address.
 *
 * This contract is used through inheritance. It introduces the virtual `_validateUpgrade()` function that must be
 * implemented in the parent contract.
 */
abstract contract UUPSExtUpgradeable is UUPSUpgradeable {
    // ------------------ Errors ---------------------------------- //

    /// @dev Thrown if the provided new implementation address is not a contract.
    error UUPSExtUpgradeable_ImplementationAddressNotContract();

    /// @dev Thrown if the provided new implementation contract address is zero.
    error UUPSExtUpgradeable_ImplementationAddressZero();

    // ------------------ Internal functions ---------------------- //

    /**
     * @dev The upgrade authorization function for UUPSProxy.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override {
        if (newImplementation == address(0)) {
            revert UUPSExtUpgradeable_ImplementationAddressZero();
        }

        if (newImplementation.code.length == 0) {
            revert UUPSExtUpgradeable_ImplementationAddressNotContract();
        }

        _validateUpgrade(newImplementation);
    }

    /**
     * @dev Executes further validation steps of the upgrade including authorization and implementation address checks.
     * @param newImplementation The address of the new implementation.
     */
    function _validateUpgrade(address newImplementation) internal virtual;
}
