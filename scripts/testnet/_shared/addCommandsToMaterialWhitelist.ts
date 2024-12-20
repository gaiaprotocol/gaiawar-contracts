import { Addressable } from "ethers";
import { ethers } from "hardhat";
import { Material } from "../../../typechain-types/index.js";

export default async function addCommandsToMaterialWhitelist(
  materialAddresses: Record<string, string>,
  addresses: (string | Addressable)[],
) {
  const Material = await ethers.getContractFactory("Material");

  for (const [name, address] of Object.entries(materialAddresses)) {
    const contract = Material.attach(address) as Material;

    const tx = await contract.addToWhitelist(addresses);
    await tx.wait();

    console.log(`Added all commands to the whitelist of ${name}`);
  }

  console.log("Done!");
}
