import { Addressable } from "ethers";
import { ethers } from "hardhat";
import { Battleground } from "../../../typechain-types/index.js";

export default async function addOperatorsToBattleground(
  battlegroundAddress: string | Addressable,
  operators: (string | Addressable)[],
) {
  const Battleground = await ethers.getContractFactory("Battleground");

  const contract = Battleground.attach(battlegroundAddress) as Battleground;

  const tx = await contract.addOperators(operators);
  await tx.wait();

  console.log(`Added operators to Battleground`);
}
