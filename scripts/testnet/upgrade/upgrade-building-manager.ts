import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const BUILDING_MANAGER_ADDRESS = "0x864C231b91B99a165a3ac9b60E2F84172Df960Af";

async function main() {
  const BuildingManager = await ethers.getContractFactory("BuildingManager");
  console.log("Upgrading BuildingManager to", network.name);

  await upgrades.upgradeProxy(BUILDING_MANAGER_ADDRESS, BuildingManager);
  console.log("BuildingManager upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
