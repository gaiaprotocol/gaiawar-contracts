import { ethers } from "hardhat";

const BATTLEGROUND_ADDRESS = "0x2764105cbc52639985733CD18f770F09F6626280";
const BUILDINGS_ADDRESS = "0xC911108F80B792A0E1f69FEd013b720CA1e49Dcd";

async function main() {
  const Battleground = await ethers.getContractFactory("Battleground");
  const contract = Battleground.attach(BATTLEGROUND_ADDRESS);

  const tx = await contract.setBuildingsContract(BUILDINGS_ADDRESS);
  await tx.wait();

  console.log("Buildings contract set on Battleground");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
