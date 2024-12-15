import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const CONSTRUCTION_ADDRESS = "0xCb3428bA809B47d0cA7eC766d7d476986CF4fC10";

async function main() {
  const Construction = await ethers.getContractFactory("Construction");
  console.log("Upgrading Construction to", network.name);

  await upgrades.upgradeProxy(CONSTRUCTION_ADDRESS, Construction);
  console.log("Construction upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
