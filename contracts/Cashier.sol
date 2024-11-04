// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlExtUpgradeable } from "./base/AccessControlExtUpgradeable.sol";
import { PausableExtUpgradeable } from "./base/PausableExtUpgradeable.sol";
import { RescuableUpgradeable } from "./base/RescuableUpgradeable.sol";

import { ICashier } from "./interfaces/ICashier.sol";
import { ICashierPrimary } from "./interfaces/ICashier.sol";
import { ICashierConfiguration } from "./interfaces/ICashier.sol";
import { ICashierShard } from "./interfaces/ICashierShard.sol";
import { ICashierShardPrimary } from "./interfaces/ICashierShard.sol";
import { ICashierHook } from "./interfaces/ICashierHook.sol";
import { ICashierHookable } from "./interfaces/ICashierHookable.sol";
import { IERC20Mintable } from "./interfaces/IERC20Mintable.sol";

import { CashierStorage } from "./CashierStorage.sol";

/**
 * @title Cashier contract
 * @author CloudWalk Inc. (See https://www.cloudwalk.io)
 * @dev Entry point contract for cash-in and cash-out operations.
 */
contract Cashier is
    CashierStorage,
    AccessControlExtUpgradeable,
    PausableExtUpgradeable,
    RescuableUpgradeable,
    UUPSUpgradeable,
    ICashier,
    ICashierHookable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // ------------------ Constants ------------------------------- //

    /// @dev The maximum number of shards.
    uint256 public constant MAX_SHARD_COUNT = 1100;

    /// @dev The role of this contract owner.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev The role of cashier that is allowed to execute the cash-in operations.
    bytes32 public constant CASHIER_ROLE = keccak256("CASHIER_ROLE");

    /// @dev The role of hook admin that is allowed to configure hooks for operations.
    bytes32 public constant HOOK_ADMIN_ROLE = keccak256("HOOK_ADMIN_ROLE");

    /// @dev The bit flag that indicates that at least one hook function is configured for a cash-out operation.
    uint256 private constant CASH_OUT_FLAG_SOME_HOOK_CONFIGURED = (1 << uint256(CashOutFlagIndex.SomeHookRegistered));

    /// @dev The mask of all bit flags that are used for the cash-out operations.
    uint256 private constant ALL_CASH_OUT_HOOK_FLAGS =
        (1 << uint256(HookIndex.CashOutRequestBefore)) +
        (1 << uint256(HookIndex.CashOutRequestAfter)) +
        (1 << uint256(HookIndex.CashOutConfirmationBefore)) +
        (1 << uint256(HookIndex.CashOutConfirmationAfter)) +
        (1 << uint256(HookIndex.CashOutReversalBefore)) +
        (1 << uint256(HookIndex.CashOutReversalAfter));

    // ------------------ Initializers ---------------------------- //

    /**
     * @dev Initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     *
     * @param token_ The address of the token to set as the underlying one.
     */
    function initialize(address token_) external initializer {
        __Cashier_init(token_);
    }

    /**
     * @dev Internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     *
     * @param token_ The address of the token to set as the underlying one.
     */
    function __Cashier_init(address token_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlExt_init_unchained();
        __Pausable_init_unchained();
        __PausableExt_init_unchained(OWNER_ROLE);
        __Rescuable_init_unchained(OWNER_ROLE);
        __UUPSUpgradeable_init_unchained();

        __Cashier_init_unchained(token_);
    }

    /**
     * @dev Unchained internal initializer of the upgradable contract.
     *
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable.
     *
     * Requirements:
     *
     * - The passed address of the underlying token must not be zero.
     *
     * @param token_ The address of the token to set as the underlying one.
     */
    function __Cashier_init_unchained(address token_) internal onlyInitializing {
        if (token_ == address(0)) {
            revert Cashier_TokenAddressZero();
        }

        _token = token_;

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(CASHIER_ROLE, OWNER_ROLE);
        _setRoleAdmin(HOOK_ADMIN_ROLE, OWNER_ROLE);
        _grantRole(OWNER_ROLE, _msgSender());
    }

    /**
     * @dev Sets {OWNER_ROLE} role as the admin role for the {HOOK_ADMIN_ROLE} role.
     */
    function initHookAdminRole() external onlyRole(OWNER_ROLE) {
        _setRoleAdmin(HOOK_ADMIN_ROLE, OWNER_ROLE);
    }

    // ------------------ Functions ------------------------------- //

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `account` and `txId` values must not be zero.
     * - The provided `amount` value must not be zero and less or equal to uint64.max.
     * - The cash-in operation with the provided `txId` must not be already executed.
     */
    function cashIn(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateAccountAmountTxId(account, amount, txId);

        uint256 err = _shard(txId).registerCashIn(account, amount, txId, CashInStatus.Executed);
        _checkShardError(err);

        emit CashIn(account, amount, txId);

        if (!IERC20Mintable(_token).mint(account, amount)) {
            revert Cashier_TokenMintingFailure();
        }
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `account`, `txId` and `releaseTime` values must not be zero.
     * - The provided `amount` value must not be zero and less or equal to uint64.max.
     * - The cash-in operation with the provided `txId` must not be already executed.
     */
    function cashInPremint(
        address account,
        uint256 amount,
        bytes32 txId,
        uint256 releaseTime
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateAccountAmountTxIdReleaseTime(account, amount, txId, releaseTime);

        uint256 err = _shard(txId).registerCashIn(account, amount, txId, CashInStatus.PremintExecuted);
        _checkShardError(err);

        emit CashInPremint(account, amount, 0, txId, releaseTime);

        IERC20Mintable(_token).premintIncrease(account, amount, releaseTime);
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `account`, `txId` and `releaseTime` values must not be zero.
     * - The cash-in operation with the provided `txId` must have the `PremintExecuted` status.
     */
    function cashInPremintRevoke(
        bytes32 txId, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 releaseTime
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateTxIdReleaseTime(txId, releaseTime);

        (uint256 err, address account, uint256 amount) = _shard(txId).revokeCashIn(txId);
        _checkShardError(err);

        emit CashInPremint(account, 0, amount, txId, releaseTime);

        IERC20Mintable(_token).premintDecrease(account, amount, releaseTime);
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The original and target release timestamps must meet the requirements of the appropriate function of the
     *   underlying token contract.
     */
    function reschedulePremintRelease(
        uint256 originalRelease,
        uint256 targetRelease
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        IERC20Mintable(_token).reschedulePremintRelease(originalRelease, targetRelease);
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The `account` and `txId` values must not be zero.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its `account` field must equal the `account` argument.
     */
    function requestCashOutFrom(
        address account,
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateAccountAmountTxId(account, amount, txId);

        (uint256 err, uint256 flags) = _shard(txId).registerCashOut(account, amount, txId);
        _checkShardError(err);

        uint256 cashOutBalance = _cashOutBalances[account] + amount;
        _cashOutBalances[account] = cashOutBalance;
        _pendingCashOutTxIds.add(txId);

        emit RequestCashOut(account, amount, cashOutBalance, txId, msg.sender);

        if (flags & CASH_OUT_FLAG_SOME_HOOK_CONFIGURED != 0) {
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutRequestBefore));
            IERC20(_token).safeTransferFrom(account, address(this), amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutRequestAfter));
        } else {
            IERC20(_token).safeTransferFrom(account, address(this), amount);
        }
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `txId` value must not be zero.
     * - The cash-out operation corresponded the provided `txId` value must have the pending status.
     */
    function confirmCashOut(bytes32 txId) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateTxId(txId);

        (uint256 err, address account, uint256 amount, uint256 flags) = _shard(txId).processCashOut(
            txId,
            CashOutStatus.Confirmed
        );
        _checkShardError(err);

        uint256 cashOutBalance = _cashOutBalances[account] - amount;
        _cashOutBalances[account] = cashOutBalance;
        _pendingCashOutTxIds.remove(txId);

        emit ConfirmCashOut(account, amount, cashOutBalance, txId);

        if (flags & CASH_OUT_FLAG_SOME_HOOK_CONFIGURED != 0) {
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationBefore));
            IERC20Mintable(_token).burn(amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationAfter));
        } else {
            IERC20Mintable(_token).burn(amount);
        }
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The provided `txId` value must not be zero.
     * - The cash-out operation corresponded the provided `txId` value must have the pending status.
     */
    function reverseCashOut(bytes32 txId) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateTxId(txId);

        (uint256 err, address account, uint256 amount, uint256 flags) = _shard(txId).processCashOut(
            txId,
            CashOutStatus.Reversed
        );
        _checkShardError(err);

        uint256 cashOutBalance = _cashOutBalances[account] - amount;
        _cashOutBalances[account] = cashOutBalance;
        _pendingCashOutTxIds.remove(txId);

        emit ReverseCashOut(account, amount, cashOutBalance, txId);

        if (flags & CASH_OUT_FLAG_SOME_HOOK_CONFIGURED != 0) {
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutReversalBefore));
            IERC20(_token).safeTransfer(account, amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutReversalAfter));
        } else {
            IERC20(_token).safeTransfer(account, amount);
        }
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The `from`, `to`, `amount` and `txId` values must not be zero.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its account address must equal the `from` argument.
     */
    function makeInternalCashOut(
        address from, // Tools: this comment prevents Prettier from formatting into a single line.
        address to,
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateAccountAccountAmountTxId(from, to, amount, txId);

        (uint256 err, uint256 flags) = _shard(txId).registerInternalCashOut(from, amount, txId);
        _checkShardError(err);

        emit InternalCashOut(from, txId, to, amount);

        if (flags & CASH_OUT_FLAG_SOME_HOOK_CONFIGURED != 0) {
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutRequestBefore));
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationBefore));
            IERC20(_token).safeTransferFrom(from, to, amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationAfter));
        } else {
            IERC20(_token).safeTransferFrom(from, to, amount);
        }
    }

    /**
     * @inheritdoc ICashierPrimary
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {CASHIER_ROLE} role.
     * - The `account`, `amount` and `txId` values must not be zero.
     * - The cash-out operation with the provided `txId` must have the `Nonexistent` or `Reversed` status.
     * - If the cash-out operation has the `Reversed` status its `account` field must equal the `account` argument.
     */
    function forceCashOut(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) external whenNotPaused onlyRole(CASHIER_ROLE) {
        _validateAccountAmountTxId(account, amount, txId);

        (uint256 err, uint256 flags) = _shard(txId).registerForcedCashOut(account, amount, txId);
        _checkShardError(err);

        emit ForcedCashOut(account, txId, amount);

        if (flags & CASH_OUT_FLAG_SOME_HOOK_CONFIGURED != 0) {
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutRequestBefore));
            IERC20(_token).safeTransferFrom(account, address(this), amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutRequestAfter));

            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationBefore));
            IERC20Mintable(_token).burn(amount);
            _callCashOutHookIfConfigured(txId, uint256(HookIndex.CashOutConfirmationAfter));
        } else {
            IERC20(_token).safeTransferFrom(account, address(this), amount);
            IERC20Mintable(_token).burn(amount);
        }
    }

    /**
     * @inheritdoc ICashierConfiguration
     *
     * @dev Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The maximum number of shards if limited by {MAX_SHARD_COUNT}.
     */
    function addShards(address[] memory shards) external onlyRole(OWNER_ROLE) {
        if (_shards.length + shards.length > MAX_SHARD_COUNT) {
            revert Cashier_ShardCountExcess();
        }

        uint256 count = shards.length;
        for (uint256 i; i < count; i++) {
            _validateShardContract(shards[i]);
            _shards.push(ICashierShard(shards[i]));
            emit ShardAdded(shards[i]);
        }
    }

    /**
     * @inheritdoc ICashierConfiguration
     *
     * @dev Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     */
    function replaceShards(uint256 fromIndex, address[] memory shards) external onlyRole(OWNER_ROLE) {
        uint256 count = _shards.length;
        if (fromIndex >= count) {
            return;
        }
        count -= fromIndex;
        if (count < shards.length) {
            revert Cashier_ShardReplacementCountExcess();
        }
        if (count > shards.length) {
            count = shards.length;
        }
        for (uint256 i = 0; i < count; i++) {
            uint256 k = fromIndex + i;
            address oldShard = address(_shards[k]);
            address newShard = shards[i];
            _validateShardContract(newShard);
            _shards[k] = ICashierShard(newShard);
            emit ShardReplaced(newShard, oldShard);
        }
    }

    /**
     * @inheritdoc ICashierConfiguration
     *
     * @dev Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     */
    function configureShardAdmin(address account, bool status) external onlyRole(OWNER_ROLE) {
        _validateAccount(account);

        for (uint256 i; i < _shards.length; i++) {
            _shards[i].setAdmin(account, status);
        }

        emit ShardAdminConfigured(account, status);
    }

    /**
     * @inheritdoc ICashierHookable
     *
     * @dev Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {HOOK_ADMIN_ROLE} role.
     * - The provided `txId` value must not be zero.
     * - The new hook flags or the callable contract address must differ from the previously set one.
     * - The new callable contract address must not be zero if the new hook flags are not zero.
     * - The new callable contract address must be zero if the new hook flags are zero.
     */
    function configureCashOutHooks(
        bytes32 txId,
        address newCallableContract,
        uint256 newHookFlags
    ) external whenNotPaused onlyRole(HOOK_ADMIN_ROLE) {
        _validateTxId(txId);

        // Resets all the expected flags and checks whether any remains
        if ((newHookFlags & ~ALL_CASH_OUT_HOOK_FLAGS) != 0) {
            revert Cashier_HookFlagsInvalid();
        }

        if (newHookFlags != 0) {
            // Sets only the needed flag, keeping other possible ones unchanged
            uint256 err = _shard(txId).setBitInCashOutFlags(txId, uint8(CASH_OUT_FLAG_SOME_HOOK_CONFIGURED));
            _checkShardError(err);
        } else {
            // Resets only the needed flag, keeping other possible ones unchanged
            uint256 err = _shard(txId).resetBitInCashOutFlags(txId, uint8(CASH_OUT_FLAG_SOME_HOOK_CONFIGURED));
            _checkShardError(err);
        }

        // Getting the hook configuration structure has been extracted from the function
        // to keep it more generic for the future possible implementation of cash-in hooks.
        HookConfig storage hooksConfig = _cashOutHookConfigs[txId];
        _configureHooks(txId, newCallableContract, newHookFlags, hooksConfig);
    }

    // ------------------ View functions -------------------------- //

    /**
     * @inheritdoc ICashierPrimary
     */
    function getCashIn(bytes32 txId) external view returns (CashInOperation memory) {
        return _shard(txId).getCashIn(txId);
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function getCashIns(bytes32[] memory txIds) external view returns (CashInOperation[] memory) {
        uint256 len = txIds.length;
        CashInOperation[] memory cashInOperations = new CashInOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashInOperations[i] = _shard(txIds[i]).getCashIn(txIds[i]);
        }
        return cashInOperations;
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function getCashOut(bytes32 txId) external view returns (CashOutOperation memory) {
        return _shard(txId).getCashOut(txId);
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function getCashOuts(bytes32[] memory txIds) external view returns (CashOutOperation[] memory) {
        uint256 len = txIds.length;
        CashOutOperation[] memory cashOutOperations = new CashOutOperation[](len);
        for (uint256 i = 0; i < len; i++) {
            cashOutOperations[i] = _shard(txIds[i]).getCashOut(txIds[i]);
        }
        return cashOutOperations;
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function getPendingCashOutTxIds(uint256 index, uint256 limit) external view returns (bytes32[] memory) {
        uint256 len = _pendingCashOutTxIds.length();
        bytes32[] memory txIds;
        if (len <= index || limit == 0) {
            txIds = new bytes32[](0);
        } else {
            len -= index;
            if (len > limit) {
                len = limit;
            }
            txIds = new bytes32[](len);
            for (uint256 i = 0; i < len; i++) {
                txIds[i] = _pendingCashOutTxIds.at(index);
                index++;
            }
        }
        return txIds;
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function cashOutBalanceOf(address account) external view returns (uint256) {
        return _cashOutBalances[account];
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function pendingCashOutCounter() external view returns (uint256) {
        return _pendingCashOutTxIds.length();
    }

    /**
     * @inheritdoc ICashierPrimary
     */
    function underlyingToken() external view returns (address) {
        return _token;
    }

    /**
     * @inheritdoc ICashierConfiguration
     */
    function getShardCount() external view returns (uint256) {
        return _shards.length;
    }

    /**
     * @inheritdoc ICashierConfiguration
     */
    function getShardByTxId(bytes32 txId) external view returns (address) {
        return address(_shard(txId));
    }

    /**
     * @inheritdoc ICashierConfiguration
     */
    function getShardRange(uint256 index, uint256 limit) external view returns (address[] memory) {
        uint256 len = _shards.length;
        address[] memory shards;
        if (len <= index || limit == 0) {
            shards = new address[](0);
        } else {
            len -= index;
            if (len > limit) {
                len = limit;
            }
            shards = new address[](len);
            for (uint256 i = 0; i < len; i++) {
                shards[i] = address(_shards[index]);
                index++;
            }
        }
        return shards;
    }

    /**
     * @inheritdoc ICashierHookable
     */
    function getCashOutHookConfig(bytes32 txId) external view returns (HookConfig memory) {
        return _cashOutHookConfigs[txId];
    }

    // ------------------ Pure functions -------------------------- //

    /**
     * @inheritdoc ICashierPrimary
     */
    function proveCashierRoot() external pure {}

    // ------------------ Internal functions ---------------------- //

    /**
     * @dev Validates the provided off-chain transaction identifier.
     * @param txId The off-chain transaction identifier to be validated.
     */
    function _validateTxId(bytes32 txId) internal pure {
        if (txId == 0) {
            revert Cashier_TxIdZero();
        }
    }

    /**
     * @dev Validates the provided amount value.
     * @param amount The amount of tokens to be validated.
     */
    function _validateAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert Cashier_AmountZero();
        }
        if (amount > type(uint64).max) {
            revert Cashier_AmountExcess();
        }
    }

    /**
     * @dev Validates the provided account address.
     * @param account The account address to be validated.
     */
    function _validateAccount(address account) internal pure {
        if (account == address(0)) {
            revert Cashier_AccountAddressZero();
        }
    }

    /**
     * @dev Validates the provided release time value.
     * @param releaseTime The release time to be validated.
     */
    function _validateReleaseTime(uint256 releaseTime) internal pure {
        if (releaseTime == 0) {
            revert Cashier_PremintReleaseTimeInappropriate();
        }
    }

    /**
     * @dev Validates the provided account, amount and txId values.
     * @param account The account address to be validated.
     * @param amount The amount of tokens to be validated.
     * @param txId The off-chain transaction identifier to be validated.
     */
    function _validateAccountAmountTxId(
        address account, // Tools: This comment prevents Prettier from formatting into a single line.
        uint256 amount,
        bytes32 txId
    ) internal pure {
        _validateAccount(account);
        _validateAmount(amount);
        _validateTxId(txId);
    }

    /**
     * @dev Validates the provided accounts, amount and txId values.
     * @param account1 The first account address to be validated.
     * @param account2 The second account address to be validated.
     * @param amount The amount of tokens to be validated.
     * @param txId The off-chain transaction identifier to be validated.
     */
    function _validateAccountAccountAmountTxId(
        address account1,
        address account2,
        uint256 amount,
        bytes32 txId
    ) internal pure {
        _validateAccount(account1);
        _validateAccount(account2);
        _validateAmount(amount);
        _validateTxId(txId);
    }

    /**
     * @dev Validates the provided account, amount, txId and releaseTime values.
     * @param account The account address to be validated.
     * @param amount The amount of tokens to be validated.
     * @param txId The off-chain transaction identifier to be validated.
     * @param releaseTime The release time to be validated.
     */
    function _validateAccountAmountTxIdReleaseTime(
        address account,
        uint256 amount,
        bytes32 txId,
        uint256 releaseTime
    ) internal pure {
        _validateAccount(account);
        _validateAmount(amount);
        _validateTxId(txId);
        _validateReleaseTime(releaseTime);
    }

    /**
     * @dev Validates the provided txId and releaseTime values.
     * @param txId The off-chain transaction identifier to be validated.
     * @param releaseTime The release time to be validated.
     */
    function _validateTxIdReleaseTime(bytes32 txId, uint256 releaseTime) internal pure {
        _validateTxId(txId);
        _validateReleaseTime(releaseTime);
    }

    /**
     * @dev Validates the provided shard.
     * @param shard The cashier shard contract address.
     */
    function _validateShardContract(address shard) internal view {
        if (shard == address(0)) {
            revert Cashier_ShardAddressZero();
        }

        if (shard.code.length == 0) {
            revert Cashier_ShardAddressNotContract();
        }

        try ICashierShard(shard).proveCashierShard() {} catch {
            revert Cashier_ContractNotShard();
        }
    }

    /**
     * @dev Validates the provided root.
     * @param root The cashier root contract address.
     */
    function _validateRootContract(address root) internal view {
        if (root == address(0)) {
            revert Cashier_RootAddressZero();
        }

        if (root.code.length == 0) {
            revert Cashier_RootAddressNotContract();
        }

        try ICashier(root).proveCashierRoot() {} catch {
            revert Cashier_ContractNotRoot();
        }
    }

    /**
     * @dev Checks the error code returned by the shard contract and reverts with the appropriate error message.
     * @param err The error code returned by the shard contract.
     */
    function _checkShardError(uint256 err) internal pure {
        if (err != uint256(ICashierShardPrimary.Error.None)) {
            if (err == uint256(ICashierShardPrimary.Error.CashInAlreadyExecuted))
                revert Cashier_CashInAlreadyExecuted();
            if (err == uint256(ICashierShardPrimary.Error.InappropriateCashInStatus))
                revert Cashier_CashInStatusInappropriate();
            if (err == uint256(ICashierShardPrimary.Error.InappropriateCashOutStatus))
                revert Cashier_CashOutStatusInappropriate();
            if (err == uint256(ICashierShardPrimary.Error.InappropriateCashOutAccount))
                revert Cashier_CashOutAccountInappropriate();
            revert Cashier_ShardErrorUnexpected(err);
        }
    }

    /**
     * @dev Returns the shard contract by the off-chain transaction identifier.
     * @param txId The off-chain transaction identifier of the related operation.
     */
    function _shard(bytes32 txId) internal view returns (ICashierShardPrimary) {
        uint256 i = uint256(keccak256(abi.encodePacked(txId)));
        i %= _shards.length;
        return _shards[i];
    }

    /**
     * @dev Configures the hook logic for a cash-out operation internally.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param newCallableContract The address of the contract that implements the hook function to be called.
     * @param newHookFlags The bit flags of the hook functions.
     * @param hooksConfig The storage reference to the hook configuration structure.
     */
    function _configureHooks(
        bytes32 txId,
        address newCallableContract,
        uint256 newHookFlags,
        HookConfig storage hooksConfig
    ) internal {
        address oldCallableContract = hooksConfig.callableContract;
        uint256 oldHookFlags = hooksConfig.hookFlags;
        if (oldCallableContract == newCallableContract && oldHookFlags == newHookFlags) {
            revert Cashier_HookFlagsAlreadyRegistered();
        }
        if (newHookFlags != 0 && newCallableContract == address(0)) {
            revert Cashier_HookCallableContractAddressZero();
        }
        if (newHookFlags == 0 && newCallableContract != address(0)) {
            revert Cashier_HookCallableContractAddressNonZero();
        }
        hooksConfig.callableContract = newCallableContract;
        hooksConfig.hookFlags = uint32(newHookFlags);

        emit CashOutHooksConfigured(
            txId, // Tools: This comment prevents Prettier from formatting into a single line.
            newCallableContract,
            oldCallableContract,
            newHookFlags,
            oldHookFlags
        );
    }

    /**
     * @dev Calls the hook function if it is configured for a cash-out operation.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param hookIndex The index of the related hook.
     */
    function _callCashOutHookIfConfigured(bytes32 txId, uint256 hookIndex) internal {
        _callHookIfConfigured(txId, hookIndex, _cashOutHookConfigs[txId]);
    }

    /**
     * @dev Calls the hook function if it is configured for an operation.
     * @param txId The off-chain transaction identifier of the related operation.
     * @param hookIndex The index of the related hook.
     * @param hooksConfig The storage reference to the hook configuration structure.
     */
    function _callHookIfConfigured(bytes32 txId, uint256 hookIndex, HookConfig storage hooksConfig) internal {
        if ((hooksConfig.hookFlags & (1 << hookIndex)) != 0) {
            ICashierHook callableContract = ICashierHook(hooksConfig.callableContract);
            callableContract.onCashierHook(hookIndex, txId);
            emit HookInvoked(
                txId, // Tools: This comment prevents Prettier from formatting into a single line.
                hookIndex,
                address(callableContract)
            );
        }
    }

    /**
     * @dev The upgrade authorization function for UUPSProxy.
     * @param newImplementation The address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(OWNER_ROLE) {
        _validateRootContract(newImplementation);
        newImplementation; // Suppresses a compiler warning about the unused variable.
    }

    // ------------------ Service functions ----------------------- //

    /**
     * @dev The version of the standard upgrade function without the second parameter for backward compatibility.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) external {
        upgradeToAndCall(newImplementation, "");
    }

    /**
     * @dev Upgrades the range of the underlying shard contracts to the a implementation.
     * @param newImplementation The address of the new shard implementation.
     */
    function upgradeShardsTo(address newImplementation) external onlyRole(OWNER_ROLE) {
        for (uint256 i = 0; i < _shards.length; i++) {
            _shards[i].upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Upgrades the root and shard contracts to the new implementations.
     * @param newRootImplementation The address of the new root implementation.
     * @param newShardImplementation The address of the new shard implementation.
     */
    function upgradeRootAndShardsTo(address newRootImplementation, address newShardImplementation) external {
        upgradeToAndCall(newRootImplementation, "");
        for (uint256 i = 0; i < _shards.length; i++) {
            _shards[i].upgradeTo(newShardImplementation);
        }
    }
}
