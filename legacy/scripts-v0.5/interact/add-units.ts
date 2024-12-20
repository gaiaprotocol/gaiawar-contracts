import { parseEther } from "ethers";
import { ethers } from "hardhat";
import { Units } from "../../../typechain-types/index.js";

const UNITS_ADDRESS = "0xa0eD07fe9aD94CAC832C10b78794D46859C6582D";

const materialAddresses = {
  wood: "0xFCDA5C6F9ECDA91E991Fe24C11A266C0a9EB158b",
  stone: "0x122481f4987038DFCE8a9F4A9bD1Ce2B53b7c051",
  iron: "0x482868a5E794beB808BdfAE0a658e8B3156046aC",
  ducat: "0xD163DACBa1F7eCd04897AD795Fb7752c0C466f93",
};

const units: {
  prerequisiteUnitId: number;
  trainingBuildingIds: number[];
  healthPoints: number;
  attackDamage: number;
  attackRange: number;
  movementRange: number;
  trainingCosts: { tokenAddress: string; amount: bigint }[];
}[] = [
  // Knight
  {
    trainingBuildingIds: [1, 2, 3], // Castles
    healthPoints: 200,
    attackDamage: 60,
    attackRange: 0,
    movementRange: 4,
    trainingCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("100") },
      { tokenAddress: materialAddresses.stone, amount: parseEther("100") },
      { tokenAddress: materialAddresses.iron, amount: parseEther("100") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("1000") },
    ],
  },
  // Swordsman
  {
    trainingBuildingIds: [4], // Training Camp
    healthPoints: 100,
    attackDamage: 50,
    attackRange: 0,
    movementRange: 4,
    trainingCosts: [
      { tokenAddress: materialAddresses.iron, amount: parseEther("200") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
  },
  // Archer
  {
    trainingBuildingIds: [5], // Achery Range
    healthPoints: 60,
    attackDamage: 20,
    attackRange: 4,
    movementRange: 3,
    trainingCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("100") },
      { tokenAddress: materialAddresses.iron, amount: parseEther("50") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
  },
  // Cavalry
  {
    trainingBuildingIds: [6], // Stable
    healthPoints: 150,
    attackDamage: 50,
    attackRange: 0,
    movementRange: 6,
    trainingCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("100") },
      { tokenAddress: materialAddresses.iron, amount: parseEther("200") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("300") },
    ],
  },
  //TODO:
  // Axe Warrior
  // Spearman
  // Shield Bearer
  // Scout
  // Crossbowman
  // Ballista
  // Catapult
  // Camel Rider
  // War Elephant
];

async function main() {
  const Units = await ethers.getContractFactory("Units");
  const contract = Units.attach(UNITS_ADDRESS) as Units;

  for (const [index, unit] of units.entries()) {
    const tx = await contract.addUnit(
      unit.trainingBuildingIds,
      unit.healthPoints,
      unit.attackDamage,
      unit.attackRange,
      unit.movementRange,
      unit.trainingCosts,
      true,
    );
    await tx.wait();

    console.log(`Unit ${index + 1} added`);
  }

  console.log("All units added");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
