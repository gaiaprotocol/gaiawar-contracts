import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const TRAINING_ADDRESS = "0x7933417099b92BDC5EFDB096E54517D26244538C";

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
