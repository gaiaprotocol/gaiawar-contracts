import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const RANGED_ATTACK_ADDRESS = "0x0Aa430E66Cab4946A65f3CBE67c34224016519d1";

async function main() {
  const RangedAttack = await ethers.getContractFactory("RangedAttack");
  console.log("Upgrading RangedAttack to", network.name);

  await upgrades.upgradeProxy(RANGED_ATTACK_ADDRESS, RangedAttack);
  console.log("RangedAttack upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
