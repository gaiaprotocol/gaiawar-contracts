import { ethers } from "hardhat";
import { MaterialFactory } from "../../../typechain-types/index.js";

const MATERIAL_FACTORY_ADDRESS = "0x9EF42F082360c606d3D0480404F47924323B4D8b";

async function main() {
  const MaterialFactory = await ethers.getContractFactory("MaterialFactory");
  const contract = MaterialFactory.attach(
    MATERIAL_FACTORY_ADDRESS,
  ) as MaterialFactory;

  for (const material of ["wood", "stone", "iron", "ducat"]) {
    const tx = await contract.createMaterial(
      `Gaia War ${material.charAt(0).toUpperCase()}${material.slice(1)}`,
      material.toUpperCase(),
      ethers.encodeBytes32String(""),
    );
    const receipt = await tx.wait();
    const materialAddress = (receipt?.logs.find((log: any) =>
      log.fragment?.name === "MaterialCreated"
    ) as any)?.args?.[1];

    console.log(
      `Material ${`Gaia War ${material.charAt(0).toUpperCase()}${
        material.slice(1)
      }`} created. Address: ${materialAddress}`,
    );
  }

  console.log("All materials created");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
