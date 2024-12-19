import { ethers, upgrades } from "hardhat";

async function main() {
  const BuildingManager = await ethers.getContractFactory("BuildingManager");

  console.log("Deploying BuildingManager...");
  const contract = await upgrades.deployProxy(BuildingManager, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("BuildingManager deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
