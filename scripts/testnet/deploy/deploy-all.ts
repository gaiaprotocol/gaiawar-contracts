import addCommandsToMaterialWhitelist from "../_shared/addCommandsToMaterialWhitelist.ts";
import addOperatorsToBattleground from "../_shared/addOperatorsToBattleground.ts";
import addOperatorsToLootVault from "../_shared/addOperatorsToLootVault.ts";
import deployBattleground from "../_shared/deployBattleground.ts";
import deployBuildingManager from "../_shared/deployBuildingManager.ts";
import deployConstruct from "../_shared/deployConstruct.ts";
import deployLootVault from "../_shared/deployLootVault.ts";
import deployMove from "../_shared/deployMove.ts";
import deployMoveAndAttack from "../_shared/deployMoveAndAttack.ts";
import deployRangedAttack from "../_shared/deployRangedAttack.ts";
import deployTrain from "../_shared/deployTrain.ts";
import deployUnitManager from "../_shared/deployUnitManager.ts";
import deployUpgradeBuilding from "../_shared/deployUpgradeBuilding.ts";
import deployUpgradeUnit from "../_shared/deployUpgradeUnit.ts";

const MATERIAL_ADDRESSES = {
  wood: "0xFCDA5C6F9ECDA91E991Fe24C11A266C0a9EB158b",
  stone: "0x122481f4987038DFCE8a9F4A9bD1Ce2B53b7c051",
  iron: "0x482868a5E794beB808BdfAE0a658e8B3156046aC",
  ducat: "0xD163DACBa1F7eCd04897AD795Fb7752c0C466f93",
};

const CLAN_EMBLEMS_ADDRESS = "0xFFa8483e3333200cBA48c9b46Da137fF7636BB95";

async function main() {
  // core
  const lootVaultAddress = await deployLootVault();
  const buildingManagerAddress = await deployBuildingManager();
  const unitManagerAddress = await deployUnitManager();
  const battlegroundAddress = await deployBattleground(
    lootVaultAddress,
    buildingManagerAddress,
  );

  // commands
  const constructAddress = await deployConstruct(
    lootVaultAddress,
    buildingManagerAddress,
    battlegroundAddress,
  );
  const upgradeBuildingAddress = await deployUpgradeBuilding(
    lootVaultAddress,
    buildingManagerAddress,
    battlegroundAddress,
  );
  const trainAddress = await deployTrain(
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  );
  const upgradeUnitAddress = await deployUpgradeUnit(
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  );
  const moveAddress = await deployMove(
    lootVaultAddress,
    unitManagerAddress,
    battlegroundAddress,
  );
  const moveAndAttackAddress = await deployMoveAndAttack(
    lootVaultAddress,
    buildingManagerAddress,
    unitManagerAddress,
    battlegroundAddress,
    CLAN_EMBLEMS_ADDRESS,
  );
  const rangedAttackAddress = await deployRangedAttack(
    lootVaultAddress,
    buildingManagerAddress,
    unitManagerAddress,
    battlegroundAddress,
    CLAN_EMBLEMS_ADDRESS,
  );
  await addOperatorsToLootVault(lootVaultAddress, [
    battlegroundAddress,
    moveAddress,
    moveAndAttackAddress,
  ]);
  await addOperatorsToBattleground(battlegroundAddress, [
    constructAddress,
    upgradeBuildingAddress,
    trainAddress,
    upgradeUnitAddress,
    moveAddress,
    moveAndAttackAddress,
    rangedAttackAddress,
  ]);
  await addCommandsToMaterialWhitelist(MATERIAL_ADDRESSES, [
    constructAddress,
    upgradeBuildingAddress,
    trainAddress,
    upgradeUnitAddress,
    moveAddress,
    moveAndAttackAddress,
    rangedAttackAddress,
  ]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
