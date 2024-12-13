import { parseEther } from "ethers";
import { ethers } from "hardhat";
import { Buildings } from "../../../typechain-types/index.js";

const BUILDINGS_ADDRESS = "0xC911108F80B792A0E1f69FEd013b720CA1e49Dcd";

const materialAddresses = {
  wood: "0xb1e50e052a2c5601BD92fddcc058ADDCFD44c6E7",
  stone: "0x63c45014DE5F0CbA76bbbA93A64D3d2DFd4f71cF",
  iron: "0x1605AE85E05B3E59Ae4728357DE39bAc81ed0277",
  ducat: "0x8D90c83bD9DBf0DB9D715378Bf4B7f3F5Ec749e5",
};

const buildings: {
  previousBuildingId: number;
  constructionCosts: { tokenAddress: string; amount: bigint }[];
  isHeadquarters: boolean;
  constructionRange: number;
}[] = [
  // Castle Level 1
  {
    previousBuildingId: 0,
    constructionCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("400") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
    isHeadquarters: true,
    constructionRange: 3,
  },
  // Castle Level 2
  {
    previousBuildingId: 1,
    constructionCosts: [
      { tokenAddress: materialAddresses.stone, amount: parseEther("400") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
    isHeadquarters: true,
    constructionRange: 3,
  },
  // Castle Level 3
  {
    previousBuildingId: 2,
    constructionCosts: [
      { tokenAddress: materialAddresses.iron, amount: parseEther("400") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
    isHeadquarters: true,
    constructionRange: 3,
  },
  // Training Camp
  {
    previousBuildingId: 0,
    constructionCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("300") },
      { tokenAddress: materialAddresses.stone, amount: parseEther("100") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("100") },
    ],
    isHeadquarters: false,
    constructionRange: 0,
  },
  // Achery Range
  {
    previousBuildingId: 0,
    constructionCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("200") },
      { tokenAddress: materialAddresses.stone, amount: parseEther("200") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("200") },
    ],
    isHeadquarters: false,
    constructionRange: 0,
  },
  // Stable
  {
    previousBuildingId: 0,
    constructionCosts: [
      { tokenAddress: materialAddresses.wood, amount: parseEther("100") },
      { tokenAddress: materialAddresses.stone, amount: parseEther("300") },
      { tokenAddress: materialAddresses.ducat, amount: parseEther("300") },
    ],
    isHeadquarters: false,
    constructionRange: 0,
  },
  // Tower
  {
    previousBuildingId: 0,
    constructionCosts: [
      { tokenAddress: materialAddresses.stone, amount: parseEther("400") },
    ],
    isHeadquarters: false,
    constructionRange: 0,
  },
];

async function main() {
  const Buildings = await ethers.getContractFactory("Buildings");
  const contract = Buildings.attach(BUILDINGS_ADDRESS) as Buildings;

  for (const [index, building] of buildings.entries()) {
    const tx = await contract.addBuilding(
      building.previousBuildingId,
      building.constructionCosts,
      building.isHeadquarters,
      building.constructionRange,
      true,
    );
    await tx.wait();

    console.log(`Building ${index + 1} added`);
  }

  console.log("All buildings added");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
