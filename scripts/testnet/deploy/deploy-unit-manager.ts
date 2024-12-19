import { ethers, upgrades } from "hardhat";

async function main() {
  const UnitManager = await ethers.getContractFactory("UnitManager");

  console.log("Deploying UnitManager...");
  const contract = await upgrades.deployProxy(UnitManager, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("UnitManager deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
