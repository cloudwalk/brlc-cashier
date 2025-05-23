// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title UUPSExtUpgradeable base contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Extends the OpenZeppelin's {UUPSUpgradeable} contract with additional checks for the new implementation address.
 */
abstract contract UUPSExtUpgradeable is UUPSUpgradeable {
    // ------------------ Errors ---------------------------------- //

    /// @dev Thrown if the provided new implementation address is not a contract.
    error UUPSExtUpgradeable_ImplementationAddressNotContract();

    /// @dev Thrown if the provided new implementation contract address is zero.
    error UUPSExtUpgradeable_ImplementationAddressZero();

    // ------------------ Initializers ---------------------------- //

    /**
     * @dev Unchained internal initializer of the upgradeable contract.
     *
     * See details: https://docs.openzeppelin.com/contracts/5.x/upgradeable#multiple-inheritance
     *
     * Note: The `..._init()` initializer has not been provided as redundant.
     */
    function __UUPSExt_init_unchained() internal onlyInitializing {}

    // ------------------ Internal functions ---------------------- //

    /**
     * @dev Overrides the upgrade authorization function for UUPSProxy.
     * @param newImplementation The address of the new implementation of a proxy smart contract.
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
     *
     * It is expected that this function will be overridden in successor contracts.
     *
     * @param newImplementation The address of the new implementation.
     */
    function _validateUpgrade(address newImplementation) internal virtual;
}
