import { ethers, upgrades } from "hardhat";

async function main() {
  const CONTRACT_NAME: string = "Cashier"; // TODO: Enter contract name
  const PROXY_ADDRESS: string = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"; // TODO: Enter proxy address

  // Upgrade options:
  // - unsafeAllowRenames: true
  // - unsafeSkipStorageCheck: true

  const factory = await ethers.getContractFactory(CONTRACT_NAME);
  const response = await upgrades.prepareUpgrade(PROXY_ADDRESS, factory);

  console.log("Upgrade prepared:", response);
}

main().then().catch(err => {
  throw err;
});
