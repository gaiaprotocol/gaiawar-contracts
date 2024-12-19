import { ethers } from "hardhat";
import { Training } from "../../../typechain-types/index.js";

const TRAINING_ADDRESS = "0x87feE369B7Fd5766950447f6a8187Fb6bB4101e5";
const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";

async function main() {
  const Training = await ethers.getContractFactory("Training");
  const contract = Training.attach(TRAINING_ADDRESS) as Training;

  const tx = await contract.setBattleground(BATTLEGROUND_ADDRESS);
  await tx.wait();

  console.log("Battleground contract set on Training");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
