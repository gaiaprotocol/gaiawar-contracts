import { ethers } from "hardhat";
import { Battleground } from "../../../typechain-types/index.js";

const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";
const TRAINING_ADDRESS = "0x87feE369B7Fd5766950447f6a8187Fb6bB4101e5";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");
  const contract = Battleground.attach(BATTLEGROUND_ADDRESS) as Battleground;

  const tx = await contract.setTrainingContract(TRAINING_ADDRESS);
  await tx.wait();

  console.log("Training contract set on Battleground");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
