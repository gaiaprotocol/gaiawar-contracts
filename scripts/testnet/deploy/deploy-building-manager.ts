import deployBuildingManager from "../_shared/deployBuildingManager.ts";

async function main() {
  await deployBuildingManager();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
