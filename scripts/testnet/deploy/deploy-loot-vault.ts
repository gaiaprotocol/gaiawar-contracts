import deployLootVault from "../_shared/deployLootVault.ts";

async function main() {
  await deployLootVault();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
