import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployUpgradeUnit(
  lootVaultAddress: string | Addressable,
  unitManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
) {
  const UpgradeUnit = await ethers.getContractFactory("UpgradeUnit");

  console.log("Deploying UpgradeUnit...");
  const contract = await upgrades.deployProxy(UpgradeUnit, [
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UpgradeUnit deployed to:", contract.target);
  return contract.target;
}
