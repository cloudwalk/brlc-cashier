// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { IERC20Mintable } from "../../interfaces/IERC20Mintable.sol";

/**
 * @title ERC20TokenMock contract
 * @dev An implementation of the {ERC20Upgradeable} contract for testing purposes
 */
contract ERC20TokenMock is ERC20Upgradeable, IERC20Mintable {
    bool public mintResult;

    /// @dev A mock premint event with the parameters that were passed to the `premintIncrease()` function.
    event MockPremintIncreasing(
        address account,
        uint256 amount,
        uint256 releaseTime
    );

    /// @dev A mock premint event with the parameters that were passed to the `premintDecrease()` function.
    event MockPremintDecreasing(
        address account,
        uint256 amount,
        uint256 releaseTime
    );

    /**
     * @dev The initialize function of the upgradable contract.
     * @param name_ The name of the token to set for this ERC20-comparable contract.
     * @param symbol_ The symbol of the token to set for this ERC20-comparable contract.
     */
    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC20_init(name_, symbol_);
        mintResult = true;
    }

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
     * @param account The address of a tokens recipient
     * @param amount The amount of tokens to increase
     * @param release The timestamp when the tokens will be released
     */
    function premintIncrease(
        address account,
        uint256 amount,
        uint256 release
    ) external {
        emit MockPremintIncreasing(account, amount, release);
    }

    /**
     * @dev Simulates the premintDecrease function by emitting the appropriate mock event.
     * @param account The address of a tokens recipient
     * @param amount The amount of tokens to decrease
     * @param release The timestamp when the tokens will be released
     */
    function premintDecrease(
        address account,
        uint256 amount,
        uint256 release
    ) external {
        emit MockPremintDecreasing(account, amount, release);
    }

    /**
     * @dev Calls the appropriate internal function to burn needed amount of tokens.
     * @param amount The amount of tokens of this contract to burn.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setMintResult(bool _newMintResult) external {
        mintResult = _newMintResult;
    }
}
