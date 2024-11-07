import { ethers, upgrades } from "hardhat";

async function main() {
  const CONTRACT_NAME: string = ""; // TODO: Enter contract name
  const ROOT_ADDRESS: string = ""; // TODO: Enter token contract address
  const SHARD_COUNTER: number = 0; // TODO Enter the shard counter

  const factory = await ethers.getContractFactory(CONTRACT_NAME);

  for (let i = 0; i < SHARD_COUNTER; ++i) {
    const proxy = await upgrades.deployProxy(
      factory,
      [ROOT_ADDRESS],
      { kind: "uups" }
    );

    await proxy.waitForDeployment();

    const numString = (i + 1).toString().padStart(3, "0");
    console.log(`Shard proxy number ${numString} deployed to:`, proxy.target);
  }
}

main().then().catch(err => {
  throw err;
});
