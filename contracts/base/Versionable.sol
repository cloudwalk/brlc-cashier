// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IVersion interface
 * @author CloudWalk Inc. (See https://cloudwalk.io)
 * @dev Defines the contract vesion.
 */
interface IVersion {
    /**
     * @dev The struct for contract version.
     */
    struct Version {
        uint8 major; // -- The major version of contract
        uint8 minor; // -- The minor version of contract
        uint8 patch; // -- The patch version of contract
    }

    /**
     * @dev Returns the version of the contract.
     */
    function $__VERSION() external pure returns (Version memory);
}

/**
 * @title Versionable contract
 * @author CloudWalk Inc. (See https://cloudwalk.io)
 * @dev Defines the contract version.
 */
abstract contract Versionable is IVersion {
    // ------------------ Pure functions -------------------------- //

    /**
     * @inheritdoc IVersion
     */
    function $__VERSION() external pure returns (Version memory) {
        return Version(4, 0, 0);
    }
}
