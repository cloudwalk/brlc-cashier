// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

/**
 * @title Version contract
 * @author CloudWalk Inc. (See https://cloudwalk.io)
 * @dev Defines the contract version.
 */
abstract contract AbstractVersion {
    /**
     * @dev The struct for contract version.
     */
    struct Version {
        uint16 major; // -- The major version of contract
        uint16 minor; // -- The minor version of contract
        uint16 patch; // -- The patch version of contract
    }

    // ------------------ Pure functions -------------------------- //

    /**
     * @dev Returns the version of the contract.
     */
    function $VERSION() external pure returns (Version memory) {
        return Version(1, 0, 0);
    }
}
