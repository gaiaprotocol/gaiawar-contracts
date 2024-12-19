import { ethers, upgrades } from "hardhat";

async function main() {
  const BuildingRegistry = await ethers.getContractFactory("BuildingRegistry");

  console.log("Deploying BuildingRegistry...");
  const buildingRegistry = await upgrades.deployProxy(BuildingRegistry, [], {
    initializer: "initialize",
  });
  await buildingRegistry.waitForDeployment();

  console.log("BuildingRegistry deployed to:", buildingRegistry.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
