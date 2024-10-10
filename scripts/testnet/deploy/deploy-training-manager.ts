import { ethers, upgrades } from "hardhat";

async function main() {
  const TrainingManager = await ethers.getContractFactory("TrainingManager");

  // Set addresses for initialization parameters
  // Note: Replace these with actual deployed contract addresses
  const assetRegistryAddress = "0x1234567890123456789012345678901234567890"; // Example address
  const unitRegistryAddress = "0x2345678901234567890123456789012345678901"; // Example address
  const buildingRegistryAddress = "0x3456789012345678901234567890123456789012"; // Example address
  const mapStorageAddress = "0x4567890123456789012345678901234567890123"; // Example address

  console.log("Deploying TrainingManager...");

  const trainingManager = await upgrades.deployProxy(TrainingManager, [
    assetRegistryAddress,
    unitRegistryAddress,
    buildingRegistryAddress,
    mapStorageAddress,
  ], {
    initializer: "initialize",
  });

  await trainingManager.waitForDeployment();

  console.log("TrainingManager deployed to:", trainingManager.target);
  console.log("Initialized with:");
  console.log(`- AssetRegistry: ${assetRegistryAddress}`);
  console.log(`- UnitRegistry: ${unitRegistryAddress}`);
  console.log(`- BuildingRegistry: ${buildingRegistryAddress}`);
  console.log(`- MapStorage: ${mapStorageAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
