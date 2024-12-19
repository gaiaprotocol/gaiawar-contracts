import { ethers, upgrades } from "hardhat";

async function main() {
  const Buildings = await ethers.getContractFactory("Buildings");

  console.log("Deploying Buildings...");
  const contract = await upgrades.deployProxy(Buildings, [], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Buildings deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
