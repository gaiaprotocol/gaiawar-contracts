import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployTrain(
  lootVaultAddress: string | Addressable,
  unitManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
) {
  const Train = await ethers.getContractFactory("Train");

  console.log("Deploying Train...");
  const contract = await upgrades.deployProxy(Train, [
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Train deployed to:", contract.target);
  return contract.target;
}
