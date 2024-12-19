import { ethers, upgrades } from "hardhat";

async function main() {
  const UpgradeUnit = await ethers.getContractFactory("UpgradeUnit");

  console.log("Deploying UpgradeUnit...");
  const contract = await upgrades.deployProxy(UpgradeUnit, [
    "0xc4033E6991e82c5C2EBEB033129Ee6F1F6d5554c", // lootVault
    "0x9a2F907fFd5382aDaF61F10c2c3764155816b570", // unitManager
    "0x47e6010ef1d04B5F60a341fcac62CB158452D298", // battleground
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UpgradeUnit deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
