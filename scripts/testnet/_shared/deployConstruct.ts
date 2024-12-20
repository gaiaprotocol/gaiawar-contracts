import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployConstruct(
  lootVaultAddress: string | Addressable,
  buildingManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
) {
  const Construct = await ethers.getContractFactory("Construct");

  console.log("Deploying Construct...");
  const contract = await upgrades.deployProxy(Construct, [
    lootVaultAddress,
    buildingManagerAddress,
    battlegroundAddress,
    7, // headquartersSearchRange
    3, // enemyBuildingSearchRange
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Construct deployed to:", contract.target);
  return contract.target;
}
