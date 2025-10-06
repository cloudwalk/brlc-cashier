import { ethers, upgrades } from "hardhat";

async function main() {
  const CONTRACT_NAME = ""; // TBD: Enter contract name
  const TOKEN_ADDRESS = ""; // TBD: Enter token contract address

  const factory = await ethers.getContractFactory(CONTRACT_NAME);
  const proxy = await upgrades.deployProxy(
    factory,
    [TOKEN_ADDRESS],
    { kind: "uups" },
  );

  await proxy.waitForDeployment();

  console.log("Root proxy deployed:", await proxy.getAddress());
}

main().catch((err) => {
  throw err;
});
