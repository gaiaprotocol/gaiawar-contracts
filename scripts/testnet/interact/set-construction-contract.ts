import { ethers } from "hardhat";
import { Battleground } from "../../../typechain-types/index.js";

const BATTLEGROUND_ADDRESS = "0x2764105cbc52639985733CD18f770F09F6626280";
const CONSTRUCTION_ADDRESS = "0xA2033689D584EB0F5ca69490b27eF9B274f2F724";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");
  const contract = Battleground.attach(BATTLEGROUND_ADDRESS) as Battleground;

  const tx = await contract.setConstructionContract(CONSTRUCTION_ADDRESS);
  await tx.wait();

  console.log("Construction contract set on Battleground");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
