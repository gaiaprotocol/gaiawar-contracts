import { Addressable } from "ethers";
import { ethers } from "hardhat";
import { LootVault } from "../../../typechain-types/index.js";

export default async function addOperatorsToLootVault(
  lootVaultAddress: string | Addressable,
  operators: (string | Addressable)[],
) {
  const LootVault = await ethers.getContractFactory("LootVault");

  const contract = LootVault.attach(lootVaultAddress) as LootVault;

  const tx = await contract.addOperators(operators);
  await tx.wait();

  console.log(`Added operators to LootVault`);
}
