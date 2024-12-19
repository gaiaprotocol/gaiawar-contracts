import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const BUILDINGS_ADDRESS = "0xC911108F80B792A0E1f69FEd013b720CA1e49Dcd";

async function main() {
  const Buildings = await ethers.getContractFactory("Buildings");
  console.log("Upgrading Buildings to", network.name);

  await upgrades.upgradeProxy(BUILDINGS_ADDRESS, Buildings);
  console.log("Buildings upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
