import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const MOVE_ADDRESS = "0xE80801cF717ce7E69665cC08EB8770605f631f2A";

async function main() {
  const Move = await ethers.getContractFactory("Move");
  console.log("Upgrading Move to", network.name);

  await upgrades.upgradeProxy(MOVE_ADDRESS, Move);
  console.log("Move upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
