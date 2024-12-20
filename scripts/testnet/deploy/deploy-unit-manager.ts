import deployUnitManager from "../_shared/deployUnitManager.ts";

async function main() {
  await deployUnitManager();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
