import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployRangedAttack(
  lootVaultAddress: string | Addressable,
  buildingManagerAddress: string | Addressable,
  unitManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
  clanEmblemsAddress: string | Addressable,
) {
  const RangedAttack = await ethers.getContractFactory("RangedAttack");

  console.log("Deploying RangedAttack...");
  const contract = await upgrades.deployProxy(RangedAttack, [
    lootVaultAddress,
    buildingManagerAddress,
    unitManagerAddress,
    battlegroundAddress,
    clanEmblemsAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("RangedAttack deployed to:", contract.target);
  return contract.target;
}
