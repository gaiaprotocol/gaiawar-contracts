import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

const BATTLEGROUND_ADDRESS = "0x0FeA20dA5F88E92F3d59b2208E5A5904c53184fD";

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
