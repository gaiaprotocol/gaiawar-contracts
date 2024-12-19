import { ethers, upgrades } from "hardhat";

async function main() {
  const UpgradeBuilding = await ethers.getContractFactory("UpgradeBuilding");

  console.log("Deploying UpgradeBuilding...");
  const contract = await upgrades.deployProxy(UpgradeBuilding, [
    "0xc4033E6991e82c5C2EBEB033129Ee6F1F6d5554c", // lootVault
    "0x3f1694b9877aD0736bEd75887Ac950E550260e1c", // buildingManager
    "0x47e6010ef1d04B5F60a341fcac62CB158452D298", // battleground
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UpgradeBuilding deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
