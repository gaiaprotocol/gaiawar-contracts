import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const UNIT_MANAGER_ADDRESS = "0x901e7cc6E1cF5E888223D4ccC84394783374d328";

async function main() {
  const UnitManager = await ethers.getContractFactory("UnitManager");
  console.log("Upgrading UnitManager to", network.name);

  await upgrades.upgradeProxy(UNIT_MANAGER_ADDRESS, UnitManager);
  console.log("UnitManager upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
