import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const CONSTRUCT_ADDRESS = "0x2ffdEEcDE0E5D2b52a18652C665d42c26D345E7B";

async function main() {
  const Construct = await ethers.getContractFactory("Construct");
  console.log("Upgrading Construct to", network.name);

  await upgrades.upgradeProxy(CONSTRUCT_ADDRESS, Construct);
  console.log("Construct upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
