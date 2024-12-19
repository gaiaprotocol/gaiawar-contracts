import { ethers } from "hardhat";
import { Construction } from "../../../typechain-types/index.js";

const CONSTRUCTION_ADDRESS = "0xCb3428bA809B47d0cA7eC766d7d476986CF4fC10";
const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";

async function main() {
  const Construction = await ethers.getContractFactory("Construction");
  const contract = Construction.attach(CONSTRUCTION_ADDRESS) as Construction;

  const tx = await contract.setBattleground(BATTLEGROUND_ADDRESS);
  await tx.wait();

  console.log("Battleground contract set on Construction");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
