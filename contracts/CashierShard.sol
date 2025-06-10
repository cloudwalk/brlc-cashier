// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { UUPSExtUpgradeable } from "./base/UUPSExtUpgradeable.sol";

import { ICashierShard } from "./interfaces/ICashierShard.sol";
import { ICashierShardPrimary } from "./interfaces/ICashierShard.sol";
import { ICashierShardConfiguration } from "./interfaces/ICashierShard.sol";
import { CashierShardStorage } from "./CashierShardStorage.sol";
import { Versionable } from "./base/Versionable.sol";

/**
 * @title CashierShard contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev The contract responsible for storing sharded cash-in and cash-out operations.
 */
contract CashierShard is CashierShardStorage, OwnableUpgradeable, UUPSExtUpgradeable, ICashierShard, Versionable {
    // ------------------ Constructor ----------------------------- //

    /**
     * @dev Constructor that prohibits the initialization of the implementation of the upgradeable contract.
     *
     * See details
     * https://docs.openzeppelin.com/upgrades-plugins/writing-upgradeable#initializing_the_implementation_contract
     *
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    // ------------------ Initializers ---------------------------- //

    /**
     * @dev Initializer of the upgradeable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     *
     * @param owner_ The address of the contract owner.
     */
    function initialize(address owner_) external initializer {
        __Ownable_init_unchained(owner_);
        __UUPSExt_init_unchained(); // This is needed only to avoid errors during coverage assessment
    }

    // ----------------------- Modifiers -------------------------- //

    modifier onlyOwnerOrAdmin() {
        if (msg.sender != owner() && !_admins[msg.sender]) {
            revert CashierShard_Unauthorized();
        }
        _;
    }

    // ------------------ Transactional functions ----------------- //

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-in operation with the provided `txId` must not be already executed.
     */
    function registerCashIn(
        address account,
        uint256 amount,
        bytes32 txId,
        CashInStatus targetStatus
    ) external onlyOwnerOrAdmin returns (uint256) {
        CashInOperation storage operation = _cashInOperations[txId];

        if (operation.status != CashInStatus.Nonexistent) {
            return uint256(Error.CashInAlreadyExecuted);
        }

        operation.account = account;
        operation.amount = uint64(amount);
        operation.status = targetStatus;

        return uint256(Error.None);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-in operation with the provided `txId` must have the `PremintExecuted` status.
     */
    function revokeCashIn(bytes32 txId) external onlyOwnerOrAdmin returns (uint256, address, uint256) {
        CashInOperation storage operation = _cashInOperations[txId];

        if (operation.status != CashInStatus.PremintExecuted) {
            return (uint256(Error.InappropriateCashInStatus), address(0), 0);
        }

        address oldAccount = operation.account;
        uint256 oldAmount = operation.amount;

        operation.account = address(0);
        operation.amount = 0;
        operation.status = CashInStatus.Nonexistent;

        return (uint256(Error.None), oldAccount, oldAmount);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its `account` field must equal the `account` argument.
     */
    function registerCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external onlyOwnerOrAdmin returns (uint256, uint256) {
        return _registerCashOut(account, amount, txId, CashOutStatus.Pending);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its account address must equal the `account` argument.
     */
    function registerInternalCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external onlyOwnerOrAdmin returns (uint256, uint256) {
        return _registerCashOut(account, amount, txId, CashOutStatus.Internal);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its account address must equal the `account` argument.
     */
    function registerForcedCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external onlyOwnerOrAdmin returns (uint256, uint256) {
        return _registerCashOut(account, amount, txId, CashOutStatus.Forced);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     * - The cash-out operation corresponding to the provided `txId` value must have the pending status.
     */
    function processCashOut(
        bytes32 txId,
        CashOutStatus targetStatus
    ) external onlyOwnerOrAdmin returns (uint256, address, uint256, uint256) {
        CashOutOperation storage operation = _cashOutOperations[txId];

        uint256 err;
        if (operation.status != CashOutStatus.Pending) {
            err = uint256(Error.InappropriateCashOutStatus);
        } else {
            err = uint256(Error.None);
            operation.status = targetStatus;
        }

        return (err, operation.account, operation.amount, operation.flags);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     */
    function setBitInCashOutFlags(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint8 bit
    ) external onlyOwnerOrAdmin returns (uint256) {
        _cashOutOperations[txId].flags |= bit;

        return uint256(Error.None);
    }

    /**
     * @inheritdoc ICashierShardPrimary
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     */
    function resetBitInCashOutFlags(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint8 bit
    ) external onlyOwnerOrAdmin returns (uint256) {
        _cashOutOperations[txId].flags &= ~bit;

        return uint256(Error.None);
    }

    /**
     * @inheritdoc ICashierShardConfiguration
     *
     * @dev Requirements:
     *
     * - The caller must be the owner or an admin.
     */
    function setAdmin(address account, bool status) external onlyOwnerOrAdmin {
        _admins[account] = status;
    }

    // ------------------ View functions -------------------------- //

    /**
     * @inheritdoc ICashierShardConfiguration
     */
    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }

    /**
     * @inheritdoc ICashierShardPrimary
     */
    function getCashIn(bytes32 txId) external view returns (CashInOperation memory) {
        return _cashInOperations[txId];
    }

    /**
     * @inheritdoc ICashierShardPrimary
     */
    function getCashOut(bytes32 txId) external view returns (CashOutOperation memory) {
        return _cashOutOperations[txId];
    }

    /**
     * @inheritdoc ICashierShardPrimary
     */
    function getCashIns(bytes32[] memory txIds) external view returns (CashInOperation[] memory) {
        uint256 len = txIds.length;
        CashInOperation[] memory cashInOperations = new CashInOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashInOperations[i] = _cashInOperations[txIds[i]];
        }
        return cashInOperations;
    }

    /**
     * @inheritdoc ICashierShardPrimary
     */
    function getCashOuts(bytes32[] memory txIds) external view returns (CashOutOperation[] memory) {
        uint256 len = txIds.length;
        CashOutOperation[] memory cashOutOperations = new CashOutOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashOutOperations[i] = _cashOutOperations[txIds[i]];
        }
        return cashOutOperations;
    }

    // ------------------ Pure functions -------------------------- //

    /**
     * @inheritdoc ICashierShard
     */
    function proveCashierShard() external pure {}

    // ------------------ Internal functions ---------------------- //

    /**
     * @dev Registers a cash-out operation internally with the provided status.
     * @param account The address of the tokens recipient.
     * @param amount The amount of tokens to be received.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param newStatus The new status of the operation to set.
     * @return The error code if the operation fails, otherwise None.
     * @return The flags field of the stored cash-out operation structure.
     */
    function _registerCashOut(
        address account, // Tools: this comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId,
        CashOutStatus newStatus
    ) internal returns (uint256, uint8) {
        CashOutOperation storage operation = _cashOutOperations[txId];

        if (operation.status != CashOutStatus.Nonexistent) {
            return (uint256(Error.InappropriateCashOutStatus), operation.flags);
        }

        operation.account = account;
        operation.amount = uint64(amount);
        operation.status = newStatus;

        return (uint256(Error.None), operation.flags);
    }

    /**
     * @dev The upgrade validation function for the UUPSExtUpgradeable contract.
     * @param newImplementation The address of the new implementation.
     */
    function _validateUpgrade(address newImplementation) internal view override onlyOwnerOrAdmin {
        try ICashierShard(newImplementation).proveCashierShard() {} catch {
            revert CashierShard_ImplementationAddressInvalid();
        }
    }

    // ------------------ Service functions ----------------------- //

    /**
     * @dev The version of the standard upgrade function without the second parameter for backward compatibility.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) external {
        upgradeToAndCall(newImplementation, "");
    }
}
