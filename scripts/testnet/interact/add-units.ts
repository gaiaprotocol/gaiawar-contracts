import { parseEther } from "ethers";
import { ethers } from "hardhat";
import { Units } from "../../../typechain-types/index.js";

const UNITS_ADDRESS = "0x2EEa1c806e7B56Fa1fb4E56Aa49F7Ada2D6bE294";

const materialAddresses = {
  wood: "0xb1e50e052a2c5601BD92fddcc058ADDCFD44c6E7",
  stone: "0x63c45014DE5F0CbA76bbbA93A64D3d2DFd4f71cF",
  iron: "0x1605AE85E05B3E59Ae4728357DE39bAc81ed0277",
  ducat: "0x8D90c83bD9DBf0DB9D715378Bf4B7f3F5Ec749e5",
};

const units: {
  trainingBuildingIds: number[];
  healthPoints: number;
  attackDamage: number;
  attackRange: number;
  movementRange: number;
  traningCosts: { tokenAddress: string; amount: bigint }[];
}[] = [
  // Knight
  {
    trainingBuildingIds: [1, 2, 3], // Castles
    healthPoints: 200,
    attackDamage: 60,
    attackRange: 0,
    movementRange: 4,
    traningCosts: [
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
    traningCosts: [
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
    traningCosts: [
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
    traningCosts: [
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
      unit.traningCosts,
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
