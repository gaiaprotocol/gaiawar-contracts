import { ethers } from "hardhat";
import { Battleground } from "../../../typechain-types/index.js";

const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";
const CONSTRUCTION_ADDRESS = "0xCb3428bA809B47d0cA7eC766d7d476986CF4fC10";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");
  const contract = Battleground.attach(BATTLEGROUND_ADDRESS) as Battleground;

  const tx = await contract.setConstructionContract(CONSTRUCTION_ADDRESS);
  await tx.wait();

  console.log("Construction contract set on Battleground");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
