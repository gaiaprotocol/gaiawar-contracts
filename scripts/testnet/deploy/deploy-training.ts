import { ethers, upgrades } from "hardhat";

const BATTLEGROUND_ADDRESS = "0x2C87b00E0436fB2f36c6a053bf4cB28D1fADF091";
const UNITS_ADDRESS = "0x2EEa1c806e7B56Fa1fb4E56Aa49F7Ada2D6bE294";

async function main() {
  const Training = await ethers.getContractFactory("Training");

  console.log("Deploying Training...");
  const contract = await upgrades.deployProxy(Training, [
    BATTLEGROUND_ADDRESS,
    UNITS_ADDRESS,
  ], {
    initializer: "initialize",
  });
  await contract.waitForDeployment();

  console.log("Training deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
