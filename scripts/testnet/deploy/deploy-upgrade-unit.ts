import deployUpgradeUnit from "../_shared/deployUpgradeUnit.ts";

async function main() {
  const lootVaultAddress = "0xc4033E6991e82c5C2EBEB033129Ee6F1F6d5554c";
  const unitManagerAddress = "0x9a2F907fFd5382aDaF61F10c2c3764155816b570";
  const battlegroundAddress = "0x47e6010ef1d04B5F60a341fcac62CB158452D298";

  await deployUpgradeUnit(
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
