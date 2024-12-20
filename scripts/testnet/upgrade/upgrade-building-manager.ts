import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const BUILDING_MANAGER_ADDRESS = "0x3f1694b9877aD0736bEd75887Ac950E550260e1c";

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
