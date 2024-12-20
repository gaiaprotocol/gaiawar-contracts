import "dotenv/config";
import { ethers, network, upgrades } from "hardhat";

const MOVE_AND_ATTACK_ADDRESS = "0xE810aaf9Ec7604D0D7A83D33C4fefFcC83Afc699";

async function main() {
  const MoveAndAttack = await ethers.getContractFactory("MoveAndAttack");
  console.log("Upgrading MoveAndAttack to", network.name);

  await upgrades.upgradeProxy(MOVE_AND_ATTACK_ADDRESS, MoveAndAttack);
  console.log("MoveAndAttack upgraded");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
