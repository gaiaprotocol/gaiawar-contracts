import addOperatorsToBattleground from "../_shared/addOperatorsToBattleground.ts";
import addOperatorsToLootVault from "../_shared/addOperatorsToLootVault.ts";

const LOOT_VAULT_ADDRESS = "0xB3d09C16f066C9Fdc3546d021eFD0bF2201C8BBf";
const BATTLEGROUND_ADDRESS = "0xfde51cC2C839f680e00D3D480f152519BBE61b5F";

const commandAddresses = {
  Construct: "0x2ffdEEcDE0E5D2b52a18652C665d42c26D345E7B",
  UpgradeBuilding: "0x02F4082E1e23F7A95ebaD4B5E4008cD6c04d3f0e",
  Train: "0xf98ea55E0f7330abC5eC83Cd35176B68838aB0fB",
  UpgradeUnit: "0x5843Cf435b9Bc404BBE5E40F4Af445Df97FA2CB6",
  Move: "0xE80801cF717ce7E69665cC08EB8770605f631f2A",
  MoveAndAttack: "0xE810aaf9Ec7604D0D7A83D33C4fefFcC83Afc699",
  RangedAttack: "0x0Aa430E66Cab4946A65f3CBE67c34224016519d1",
};

async function main() {
  await addOperatorsToLootVault(LOOT_VAULT_ADDRESS, [
    BATTLEGROUND_ADDRESS,
    commandAddresses.MoveAndAttack,
  ]);
  await addOperatorsToBattleground(BATTLEGROUND_ADDRESS, [
    commandAddresses.Construct,
    commandAddresses.UpgradeBuilding,
    commandAddresses.Train,
    commandAddresses.UpgradeUnit,
    commandAddresses.Move,
    commandAddresses.MoveAndAttack,
    commandAddresses.RangedAttack,
  ]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
