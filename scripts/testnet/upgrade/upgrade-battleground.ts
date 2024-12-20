import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

const BATTLEGROUND_ADDRESS = "0x204C9E976d3acfa1d43D3b16970a3917617AF42a";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");
  console.log("Upgrading Battleground to", network.name);

  await upgrades.upgradeProxy(BATTLEGROUND_ADDRESS, Battleground);
  console.log("Battleground upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
