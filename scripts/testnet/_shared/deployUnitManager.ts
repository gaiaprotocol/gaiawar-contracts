import { ethers, upgrades } from "hardhat";

export default async function deployUnitManager() {
  const UnitManager = await ethers.getContractFactory("UnitManager");

  console.log("Deploying UnitManager...");
  const contract = await upgrades.deployProxy(UnitManager, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UnitManager deployed to:", contract.target);
  return contract.target;
}
