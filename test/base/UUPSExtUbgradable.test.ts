import { ethers, network, upgrades } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { connect } from "../../test-utils/eth";

const ADDRESS_ZERO = ethers.ZeroAddress;

async function setUpFixture<T>(func: () => Promise<T>): Promise<T> {
  if (network.name === "hardhat") {
    return loadFixture(func);
  } else {
    return func();
  }
}

describe("Contracts 'UUPSExtUpgradeable'", async () => {
  // Errors of the lib contracts
  const REVERT_ERROR_IMPLEMENTATION_ADDRESS_NOT_CONTRACT = "UUPSExtUpgradeable_ImplementationAddressNotContract";
  const REVERT_ERROR_IMPLEMENTATION_ADDRESS_ZERO = "UUPSExtUpgradeable_ImplementationAddressZero";

  // Events of the contracts under test
  const EVENT_NAME_MOCK_VALIDATE_UPGRADE_CALL = "MockValidateUpgradeCall";

  let uupsExtensionFactory: ContractFactory;
  let deployer: HardhatEthersSigner;

  before(async () => {
    [deployer] = await ethers.getSigners();

    // The contract factory with the explicitly specified deployer account
    uupsExtensionFactory = await ethers.getContractFactory("UUPSExtUpgradeableMock");
    uupsExtensionFactory = uupsExtensionFactory.connect(deployer);
  });

  async function deployContract(): Promise<{ uupsExtension: Contract }> {
    let uupsExtension: Contract = await upgrades.deployProxy(uupsExtensionFactory, [], { initializer: false });
    await uupsExtension.waitForDeployment();
    uupsExtension = connect(uupsExtension, deployer); // Explicitly specifying the initial account

    return { uupsExtension };
  }

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
        .to.be.revertedWithCustomError(uupsExtension, REVERT_ERROR_IMPLEMENTATION_ADDRESS_ZERO);
    });

    it("Is reverted if the new implementation address is not a contract", async () => {
      const { uupsExtension } = await setUpFixture(deployContract);
      await expect(uupsExtension.upgradeToAndCall(deployer.address, "0x"))
        .to.be.revertedWithCustomError(uupsExtension, REVERT_ERROR_IMPLEMENTATION_ADDRESS_NOT_CONTRACT);
    });
  });
});
