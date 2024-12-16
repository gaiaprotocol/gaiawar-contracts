import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const UNITS_ADDRESS = "0x2EEa1c806e7B56Fa1fb4E56Aa49F7Ada2D6bE294";

async function main() {
  const Units = await ethers.getContractFactory("Units");
  console.log("Upgrading Units to", network.name);

  await upgrades.upgradeProxy(UNITS_ADDRESS, Units);
  console.log("Units upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
