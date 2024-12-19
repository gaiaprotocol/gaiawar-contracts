import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const TRAINING_ADDRESS = "0x87feE369B7Fd5766950447f6a8187Fb6bB4101e5";

async function main() {
  const Training = await ethers.getContractFactory("Training");
  console.log("Upgrading Training to", network.name);

  await upgrades.upgradeProxy(TRAINING_ADDRESS, Training);
  console.log("Training upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
