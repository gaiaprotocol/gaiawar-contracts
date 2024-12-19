import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const UNITS_ADDRESS = "0xa0eD07fe9aD94CAC832C10b78794D46859C6582D";

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
