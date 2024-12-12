import { ethers, upgrades } from "hardhat";

async function main() {
  const AssetRegistry = await ethers.getContractFactory("AssetRegistry");

  console.log("Deploying AssetRegistry...");
  const assetRegistry = await upgrades.deployProxy(AssetRegistry, [], {
    initializer: "initialize",
  });
  await assetRegistry.waitForDeployment();

  console.log("AssetRegistry deployed to:", assetRegistry.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
