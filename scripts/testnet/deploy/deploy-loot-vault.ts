import { ethers, network, upgrades } from "hardhat";

async function main() {
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
      initialOwner: account1.address,
    },
  );
  await contract.waitForDeployment();

  console.log("LootVault deployed to:", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
