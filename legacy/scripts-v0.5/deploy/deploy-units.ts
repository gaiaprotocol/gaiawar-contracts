import { ethers, upgrades } from "hardhat";

async function main() {
  const Units = await ethers.getContractFactory("Units");

  console.log("Deploying Units...");
  const contract = await upgrades.deployProxy(Units, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Units deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
