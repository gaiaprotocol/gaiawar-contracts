import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployMove(
  lootVaultAddress: string | Addressable,
  unitManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
) {
  const Move = await ethers.getContractFactory("Move");

  console.log("Deploying Move...");
  const contract = await upgrades.deployProxy(Move, [
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Move deployed to:", contract.target);
  return contract.target;
}
