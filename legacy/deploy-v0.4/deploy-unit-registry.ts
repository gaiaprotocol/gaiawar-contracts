import { ethers, upgrades } from "hardhat";

async function main() {
  const UnitRegistry = await ethers.getContractFactory("UnitRegistry");

  console.log("Deploying UnitRegistry...");
  const unitRegistry = await upgrades.deployProxy(UnitRegistry, [], {
    initializer: "initialize",
  });
  await unitRegistry.waitForDeployment();

  console.log("UnitRegistry deployed to:", unitRegistry.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
