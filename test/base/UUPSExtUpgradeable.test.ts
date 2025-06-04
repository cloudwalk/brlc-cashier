import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { connect } from "../../test-utils/eth";
import { setUpFixture } from "../../test-utils/common";

const ADDRESS_ZERO = ethers.ZeroAddress;

describe("Contracts 'UUPSExtUpgradeable'", async () => {
  // Events of the contracts under test
  const EVENT_NAME_MOCK_VALIDATE_UPGRADE_CALL = "MockValidateUpgradeCall";

  // Errors of the lib contracts
  const ERROR_NAME_INVALID_INITIALIZATION = "InvalidInitialization";
  const ERROR_NAME_NOT_INITIALIZING = "NotInitializing";

  // Errors of the contract under test
  const ERROR_NAME_IMPLEMENTATION_ADDRESS_NOT_CONTRACT = "UUPSExtUpgradeable_ImplementationAddressNotContract";
  const ERROR_NAME_IMPLEMENTATION_ADDRESS_ZERO = "UUPSExtUpgradeable_ImplementationAddressZero";

  let uupsExtensionFactory: ContractFactory;
  let deployer: HardhatEthersSigner;

  before(async () => {
    [deployer] = await ethers.getSigners();

    // The contract factory with the explicitly specified deployer account
    uupsExtensionFactory = await ethers.getContractFactory("UUPSExtUpgradeableMock");
    uupsExtensionFactory = uupsExtensionFactory.connect(deployer);
  });

  async function deployContract(): Promise<{ uupsExtension: Contract }> {
    // The contract under test with the explicitly specified initial account
    let uupsExtension = await upgrades.deployProxy(uupsExtensionFactory, []) as Contract;
    await uupsExtension.waitForDeployment();
    uupsExtension = connect(uupsExtension, deployer); // Explicitly specifying the initial account

    return { uupsExtension };
  }

  describe("Function 'initialize()' and internal initializers", async () => {
    it("The external initializer is reverted if it is called a second time", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);
      await expect(uupsExtension.initialize())
        .to.be.revertedWithCustomError(uupsExtension, ERROR_NAME_INVALID_INITIALIZATION);
    });

    it("The internal unchained initializer is reverted if it is called outside the init process", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);
      await expect(uupsExtension.callParentInitializerUnchained())
        .to.be.revertedWithCustomError(uupsExtension, ERROR_NAME_NOT_INITIALIZING);
    });
  });

  describe("Function 'upgradeToAndCall()'", async () => {
    it("Executes as expected", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);

      const newImplementation = await uupsExtensionFactory.deploy();
      await newImplementation.waitForDeployment();
      const newImplementationAddress = await newImplementation.getAddress();

      await expect(uupsExtension.upgradeToAndCall(newImplementationAddress, "0x"))
        .to.emit(uupsExtension, EVENT_NAME_MOCK_VALIDATE_UPGRADE_CALL)
        .withArgs(newImplementationAddress);
    });

    it("Is reverted if the new implementation address is zero", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);
      await expect(uupsExtension.upgradeToAndCall(ADDRESS_ZERO, "0x"))
        .to.be.revertedWithCustomError(uupsExtension, ERROR_NAME_IMPLEMENTATION_ADDRESS_ZERO);
    });

    it("Is reverted if the new implementation address is not a contract", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);
      await expect(uupsExtension.upgradeToAndCall(deployer.address, "0x"))
        .to.be.revertedWithCustomError(uupsExtension, ERROR_NAME_IMPLEMENTATION_ADDRESS_NOT_CONTRACT);
    });
  });
});
