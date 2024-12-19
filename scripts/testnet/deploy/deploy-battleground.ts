import { ethers, upgrades } from "hardhat";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");

  console.log("Deploying Battleground...");
  const contract = await upgrades.deployProxy(Battleground, [
    100, // width
    100, // height
    50, // maxUnitsPerTile
    "0xc4033E6991e82c5C2EBEB033129Ee6F1F6d5554c", // lootVault
    "0x3f1694b9877aD0736bEd75887Ac950E550260e1c", // buildingManager
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
