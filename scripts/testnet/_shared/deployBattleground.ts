import { Addressable } from "ethers";
import { ethers, upgrades } from "hardhat";

export default async function deployBattleground(
  lootVaultAddress: string | Addressable,
  buildingManagerAddress: string | Addressable,
) {
  const Battleground = await ethers.getContractFactory("Battleground");

  console.log("Deploying Battleground...");
  const contract = await upgrades.deployProxy(Battleground, [
    100, // width
    100, // height
    50, // maxUnitsPerTile
    lootVaultAddress,
    buildingManagerAddress,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Battleground deployed to:", contract.target);
  return contract.target;
}
