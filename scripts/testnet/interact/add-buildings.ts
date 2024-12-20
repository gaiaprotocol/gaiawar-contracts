import { parseEther } from "ethers";
import { ethers } from "hardhat";
import { BuildingManager } from "../../../typechain-types/index.js";

const BUILDING_MANAGER_ADDRESS = "0x864C231b91B99a165a3ac9b60E2F84172Df960Af";

const materialAddresses = {
  wood: "0xFCDA5C6F9ECDA91E991Fe24C11A266C0a9EB158b",
  stone: "0x122481f4987038DFCE8a9F4A9bD1Ce2B53b7c051",
  iron: "0x482868a5E794beB808BdfAE0a658e8B3156046aC",
  ducat: "0xD163DACBa1F7eCd04897AD795Fb7752c0C466f93",
};

enum TokenType {
  ERC20,
  ERC1155,
}

const buildings: {
  prerequisiteBuildingId: number;
  isHeadquarters: boolean;
  constructionRange: number;
  healthBoostPercentage: number; // 1-10000 (0.01% - 100%)
  damageBoostPercentage: number; // 1-10000 (0.01% - 100%)
  constructionCost: {
    tokenType: TokenType;
    tokenAddress: string;
    tokenId: number;
    amount: bigint;
  }[];
  canBeConstructed: boolean;
}[] = [
  // Castle Level 1
  {
    prerequisiteBuildingId: 0,
    isHeadquarters: true,
    constructionRange: 3,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("400"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    canBeConstructed: true,
  },
  // Castle Level 2
  {
    prerequisiteBuildingId: 1,
    isHeadquarters: true,
    constructionRange: 5,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.stone,
        tokenId: 0,
        amount: parseEther("400"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    canBeConstructed: true,
  },
  // Castle Level 3
  {
    prerequisiteBuildingId: 2,
    isHeadquarters: true,
    constructionRange: 7,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.iron,
        tokenId: 0,
        amount: parseEther("400"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    canBeConstructed: true,
  },
  // Training Camp
  {
    prerequisiteBuildingId: 0,
    isHeadquarters: false,
    constructionRange: 0,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("300"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.stone,
        tokenId: 0,
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    canBeConstructed: true,
  },
  // Achery Range
  {
    prerequisiteBuildingId: 0,
    isHeadquarters: false,
    constructionRange: 0,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("200"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.stone,
        tokenId: 0,
        amount: parseEther("200"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("200"),
      },
    ],
    canBeConstructed: true,
  },
  // Stable
  {
    prerequisiteBuildingId: 0,
    isHeadquarters: false,
    constructionRange: 0,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.stone,
        tokenId: 0,
        amount: parseEther("300"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("300"),
      },
    ],
    canBeConstructed: true,
  },
  // Tower
  {
    prerequisiteBuildingId: 0,
    isHeadquarters: false,
    constructionRange: 0,
    healthBoostPercentage: 2000,
    damageBoostPercentage: 2000,
    constructionCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.stone,
        tokenId: 0,
        amount: parseEther("400"),
      },
    ],
    canBeConstructed: true,
  },
];

async function main() {
  const BuildingManager = await ethers.getContractFactory("BuildingManager");
  const contract = BuildingManager.attach(
    BUILDING_MANAGER_ADDRESS,
  ) as BuildingManager;

  for (const [index, building] of buildings.entries()) {
    const tx = await contract.addBuilding(building);
    await tx.wait();

    console.log(`Building ${index + 1} added`);
  }

  console.log("All BuildingManager added");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
