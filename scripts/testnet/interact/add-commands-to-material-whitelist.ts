import { ethers } from "hardhat";
import { Material } from "../../../typechain-types/index.js";

const materialAddresses = {
  wood: "0xFCDA5C6F9ECDA91E991Fe24C11A266C0a9EB158b",
  stone: "0x122481f4987038DFCE8a9F4A9bD1Ce2B53b7c051",
  iron: "0x482868a5E794beB808BdfAE0a658e8B3156046aC",
  ducat: "0xD163DACBa1F7eCd04897AD795Fb7752c0C466f93",
};

const commandAddresses = {
  Construct: "0xBCF89848fC61D163798064383840A6Fa7A8594E3",
  UpgradeBuilding: "0xcF60549fb943b682Dd7E9f7649fea84d1ed5Eb2B",
  Train: "0xB4d5bA57c2f589851950d6C3512b6a18A12Aeb9b",
  UpgradeUnit: "0x9D4F0549319D1477D2B535FaFCEA59af429D8a39",
  Move: "0x954381Be392B2ba6919BF55A7197874dF2915426",
  MoveAndAttack: "0xa610ECcaCDB247C60ca3A4E3Ad93287D35F3fA18",
  RangedAttack: "0x5Aed8F6447fc4A0cd84fDDe8f736d77526EE2F52",
};

async function main() {
  const Material = await ethers.getContractFactory("Material");

  for (const [name, address] of Object.entries(materialAddresses)) {
    const contract = Material.attach(address) as Material;

    const tx = await contract.addToWhitelist(Object.values(commandAddresses));
    await tx.wait();

    console.log(`Added all commands to the whitelist of ${name}`);
  }

  console.log("Done!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
