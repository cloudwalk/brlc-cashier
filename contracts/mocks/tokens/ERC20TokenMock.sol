// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IERC20Mintable } from "../../interfaces/IERC20Mintable.sol";

/**
 * @title ERC20TokenMock contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev An implementation of the {ERC20Upgradeable} contract for testing purposes.
 */
contract ERC20TokenMock is ERC20, IERC20Mintable {
    /// @dev The result of minting function.
    bool public mintResult;

    // ------------------ Events ---------------------------------- //

    /// @dev A mock premint event with the parameters that were passed to the `premintIncrease()` function.
    event MockPremintIncreasing(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 releaseTime
    );

    /// @dev A mock premint event with the parameters that were passed to the `premintDecrease()` function.
    event MockPremintDecreasing(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 releaseTime
    );

    /// @dev A mock premint event with the parameters that were passed to the `reschedulePremintRelease()` function.
    event MockPremintReleaseRescheduling(
        uint256 originalRelease, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 targetRelease
    );

    // ------------------ Constructor ----------------------------- //

    /**
     * @dev Initializer of the upgradeable contract.
     * @param name_ The name of the token to set for this ERC20-comparable contract.
     * @param symbol_ The symbol of the token to set for this ERC20-comparable contract.
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        mintResult = true;
    }

    // ------------------ Transactional functions ----------------- //

    /**
     * @dev Calls the appropriate internal function to mint needed amount of tokens for an account.
     * @param account The address of an account to mint for.
     * @param amount The amount of tokens to mint.
     */
    function mint(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return mintResult;
    }

    /**
     * @dev Simulates the premintIncrease function by emitting the appropriate mock event.
     * @param account The address of a tokens recipient.
     * @param amount The amount of tokens to increase.
     * @param release The timestamp when the tokens will be released.
     */
    function premintIncrease(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 release
    ) external {
        emit MockPremintIncreasing(account, amount, release);
    }

    /**
     * @dev Simulates the premintDecrease function by emitting the appropriate mock event.
     * @param account The address of a tokens recipient.
     * @param amount The amount of tokens to decrease.
     * @param release The timestamp when the tokens will be released.
     */
    function premintDecrease(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        uint256 release
    ) external {
        emit MockPremintDecreasing(account, amount, release);
    }

    /**
     * @dev Simulates the reschedulePremintRelease function by emitting the appropriate mock event.
     * @param originalRelease The premint release timestamp to be rescheduled.
     * @param targetRelease The target premint release timestamp to be set during the rescheduling.
     */
    function reschedulePremintRelease(uint256 originalRelease, uint256 targetRelease) external {
        emit MockPremintReleaseRescheduling(originalRelease, targetRelease);
    }

    /**
     * @dev Calls the appropriate internal function to burn needed amount of tokens.
     * @param amount The amount of tokens of this contract to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Sets the mint result to the new value.
     * @param newMintResult The new value to set for the mint result.
     */
    function setMintResult(bool newMintResult) external {
        mintResult = newMintResult;
    }
}
