import { ethers, upgrades } from "hardhat";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");

  console.log("Deploying Battleground...");
  const contract = await upgrades.deployProxy(Battleground, [
    -50, // minTileX
    -50, // minTileY
    49, // maxTileX
    49, // maxTileY
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
