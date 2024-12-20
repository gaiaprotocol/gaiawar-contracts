import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployUpgradeBuilding(
  lootVaultAddress: string | Addressable,
  buildingManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
) {
  const UpgradeBuilding = await ethers.getContractFactory("UpgradeBuilding");

  console.log("Deploying UpgradeBuilding...");
  const contract = await upgrades.deployProxy(UpgradeBuilding, [
    lootVaultAddress,
    buildingManagerAddress,
    battlegroundAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UpgradeBuilding deployed to:", contract.target);
  return contract.target;
}
