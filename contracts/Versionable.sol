// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IVersion.sol";

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
