import deployConstruct from "../_shared/deployConstruct.ts";

async function main() {
  const lootVaultAddress = "0xc4033E6991e82c5C2EBEB033129Ee6F1F6d5554c";
  const buildingManagerAddress = "0x3f1694b9877aD0736bEd75887Ac950E550260e1c";
  const battlegroundAddress = "0x47e6010ef1d04B5F60a341fcac62CB158452D298";

  await deployConstruct(
    lootVaultAddress,
    buildingManagerAddress,
    battlegroundAddress,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
