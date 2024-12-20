import { parseEther } from "ethers";
import { ethers } from "hardhat";
import { UnitManager } from "../../../typechain-types/index.js";

const UNIT_MANAGER_ADDRESS = "0x901e7cc6E1cF5E888223D4ccC84394783374d328";

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

const units: {
  prerequisiteUnitId: number;
  trainingBuildingIds: number[];
  healthPoints: number;
  attackDamage: number;
  attackRange: number;
  movementRange: number;
  healthBoostPercentage: number; // 1-10000 (0.01% - 100%)
  damageBoostPercentage: number; // 1-10000 (0.01% - 100%)
  trainingCost: {
    tokenType: TokenType;
    tokenAddress: string;
    tokenId: number;
    amount: bigint;
  }[];
  rangedAttackCost: {
    tokenType: TokenType;
    tokenAddress: string;
    tokenId: number;
    amount: bigint;
  }[];
  canBeTrained: boolean;
}[] = [
  // Knight
  {
    prerequisiteUnitId: 0,
    trainingBuildingIds: [1, 2, 3], // Castles
    healthPoints: 200,
    attackDamage: 60,
    attackRange: 0,
    movementRange: 4,
    healthBoostPercentage: 1000,
    damageBoostPercentage: 500,
    trainingCost: [
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
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.iron,
        tokenId: 0,
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("1000"),
      },
    ],
    rangedAttackCost: [],
    canBeTrained: true,
  },
  // Swordsman
  {
    prerequisiteUnitId: 0,
    trainingBuildingIds: [4], // Training Camp
    healthPoints: 100,
    attackDamage: 50,
    attackRange: 0,
    movementRange: 4,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    trainingCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.iron,
        tokenId: 0,
        amount: parseEther("200"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    rangedAttackCost: [],
    canBeTrained: true,
  },
  // Archer
  {
    prerequisiteUnitId: 0,
    trainingBuildingIds: [5], // Achery Range
    healthPoints: 60,
    attackDamage: 20,
    attackRange: 4,
    movementRange: 3,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    trainingCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.iron,
        tokenId: 0,
        amount: parseEther("50"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("100"),
      },
    ],
    rangedAttackCost: [{
      tokenType: TokenType.ERC20,
      tokenAddress: materialAddresses.wood,
      tokenId: 0,
      amount: parseEther("2"),
    }],
    canBeTrained: true,
  },
  // Cavalry
  {
    prerequisiteUnitId: 0,
    trainingBuildingIds: [6], // Stable
    healthPoints: 150,
    attackDamage: 50,
    attackRange: 0,
    movementRange: 6,
    healthBoostPercentage: 0,
    damageBoostPercentage: 0,
    trainingCost: [
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.wood,
        tokenId: 0,
        amount: parseEther("100"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.iron,
        tokenId: 0,
        amount: parseEther("200"),
      },
      {
        tokenType: TokenType.ERC20,
        tokenAddress: materialAddresses.ducat,
        tokenId: 0,
        amount: parseEther("300"),
      },
    ],
    rangedAttackCost: [],
    canBeTrained: true,
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
  const UnitManager = await ethers.getContractFactory("UnitManager");
  const contract = UnitManager.attach(UNIT_MANAGER_ADDRESS) as UnitManager;

  for (const [index, unit] of units.entries()) {
    const tx = await contract.addUnit(unit);
    await tx.wait();

    console.log(`Unit ${index + 1} added`);
  }

  console.log("All UnitManager added");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
