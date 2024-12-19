import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";

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
