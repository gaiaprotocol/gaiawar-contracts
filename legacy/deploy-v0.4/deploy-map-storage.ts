import { ethers, upgrades } from "hardhat";

async function main() {
  const MapStorage = await ethers.getContractFactory("MapStorage");

  // Set initialization parameters
  const mapRows = 100; // Example value, adjust as needed
  const mapCols = 100; // Example value, adjust as needed
  const maxUnitsPerTile = 10; // Example value, adjust as needed

  console.log("Deploying MapStorage...");
  const mapStorage = await upgrades.deployProxy(MapStorage, [
    mapRows,
    mapCols,
    maxUnitsPerTile,
  ], {
    initializer: "initialize",
  });
  await mapStorage.waitForDeployment();

  console.log("MapStorage deployed to:", mapStorage.target);
  console.log("Initialized with:");
  console.log(`- Map size: ${mapRows} x ${mapCols}`);
  console.log(`- Max units per tile: ${maxUnitsPerTile}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
