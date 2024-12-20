import { ethers, network, upgrades } from "hardhat";

export default async function deployLootVault() {
  const LootVault = await ethers.getContractFactory("LootVault");
  console.log("Deploying LootVault to", network.name);

  const [account1] = await ethers.getSigners();

  const contract = await upgrades.deployProxy(
    LootVault,
    [
      account1.address,
      100000000000000000n,
    ],
    {
      initializer: "initialize",
    },
  );
  await contract.waitForDeployment();

  console.log("LootVault deployed to:", contract.target);
  return contract.target;
}
