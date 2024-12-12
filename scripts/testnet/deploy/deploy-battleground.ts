import { ethers, upgrades } from "hardhat";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");

  console.log("Deploying Battleground...");
  const contract = await upgrades.deployProxy(Battleground, [
    100, // width
    100, // height
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Battleground deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
