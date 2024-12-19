import fs from "fs";
import path from "path";

const CONTRACT_PATHS = [
  "core/Battleground",
  "data/BuildingManager",
  "data/UnitManager",
  "commands/Construct",
  "commands/UpgradeBuilding",
  "commands/Train",
  "commands/UpgradeUnit",
  "commands/Move",
  "commands/MoveAndAttack",
  "commands/RangedAttack",
];

for (const contractPath of CONTRACT_PATHS) {
  const filename = path.basename(contractPath, path.extname(contractPath));
  const abiSource = fs.readFileSync(
    `../artifacts/contracts/${contractPath}.sol/${filename}.json`,
    "utf-8",
  );
  fs.writeFileSync(
    `../../gaiawar-interface/game/contracts/artifacts/${contractPath}.json`,
    abiSource,
  );
}
