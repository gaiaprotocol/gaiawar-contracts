import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployMoveAndAttack(
  lootVaultAddress: string | Addressable,
  buildingManagerAddress: string | Addressable,
  unitManagerAddress: string | Addressable,
  battlegroundAddress: string | Addressable,
  clanEmblemsAddress: string | Addressable,
) {
  const MoveAndAttack = await ethers.getContractFactory("MoveAndAttack");

  console.log("Deploying MoveAndAttack...");
  const contract = await upgrades.deployProxy(MoveAndAttack, [
    lootVaultAddress,
    buildingManagerAddress,
    unitManagerAddress,
    battlegroundAddress,
    clanEmblemsAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("MoveAndAttack deployed to:", contract.target);
  return contract.target;
}
