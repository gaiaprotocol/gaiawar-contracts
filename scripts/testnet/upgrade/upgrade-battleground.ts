import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

const BATTLEGROUND_ADDRESS = "0xfde51cC2C839f680e00D3D480f152519BBE61b5F";

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
