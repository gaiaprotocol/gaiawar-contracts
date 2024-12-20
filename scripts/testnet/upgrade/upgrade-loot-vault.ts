import { ethers, network, upgrades } from "hardhat";
import "dotenv/config";

const LOOT_VAULT_ADDRESS = "0xB3d09C16f066C9Fdc3546d021eFD0bF2201C8BBf";

async function main() {
  const LootVault = await ethers.getContractFactory("LootVault");
  console.log("Upgrading LootVault to", network.name);

  await upgrades.upgradeProxy(LOOT_VAULT_ADDRESS, LootVault);
  console.log("LootVault upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
