import { ethers, upgrades } from "hardhat";

async function main() {
  const ConstructionManager = await ethers.getContractFactory(
    "ConstructionManager",
  );

  // Set addresses for initialization parameters
  // Note: Replace these with actual deployed contract addresses
  const assetRegistryAddress = "0x1234567890123456789012345678901234567890"; // Example address
  const buildingRegistryAddress = "0x2345678901234567890123456789012345678901"; // Example address
  const mapStorageAddress = "0x3456789012345678901234567890123456789012"; // Example address

  console.log("Deploying ConstructionManager...");

  const constructionManager = await upgrades.deployProxy(ConstructionManager, [
    assetRegistryAddress,
    buildingRegistryAddress,
    mapStorageAddress,
  ], {
    initializer: "initialize",
  });

  await constructionManager.waitForDeployment();

  console.log("ConstructionManager deployed to:", constructionManager.target);
  console.log("Initialized with:");
  console.log(`- AssetRegistry: ${assetRegistryAddress}`);
  console.log(`- BuildingRegistry: ${buildingRegistryAddress}`);
  console.log(`- MapStorage: ${mapStorageAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
