import { ethers, upgrades } from "hardhat";

const BATTLEGROUND_ADDRESS = "0x24623995D0AD6354943011256893720115e37E5a";
const BUILDINGS_ADDRESS = "0xC911108F80B792A0E1f69FEd013b720CA1e49Dcd";

async function main() {
  const Construction = await ethers.getContractFactory("Construction");

  console.log("Deploying Construction...");
  const contract = await upgrades.deployProxy(Construction, [
    BATTLEGROUND_ADDRESS,
    BUILDINGS_ADDRESS,
    7, // headquartersSearchRange
    3, // enemyBuildingSearchRange
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Construction deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
