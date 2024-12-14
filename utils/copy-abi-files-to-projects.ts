import fs from "fs";
import path from "path";

const CONTRACT_PATHS = [
  "Battleground",
  "entities/Buildings",
  "commands/Construction",
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
