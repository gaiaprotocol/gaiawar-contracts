import { ethers, upgrades } from "hardhat";

export default async function deployBuildingManager() {
  const BuildingManager = await ethers.getContractFactory("BuildingManager");

  console.log("Deploying BuildingManager...");
  const contract = await upgrades.deployProxy(BuildingManager, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("BuildingManager deployed to:", contract.target);
  return contract.target;
}
