import { ethers } from "hardhat";
import { Construction } from "../../../typechain-types/index.js";

const CONSTRUCTION_ADDRESS = "0xCb3428bA809B47d0cA7eC766d7d476986CF4fC10";
const BATTLEGROUND_ADDRESS = "0x24623995D0AD6354943011256893720115e37E5a";

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
