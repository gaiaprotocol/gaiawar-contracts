import fs from "fs";
import path from "path";

const CONTRACTS = [
  "MapStorage",
];

for (const contract of CONTRACTS) {
  const filename = path.basename(contract, path.extname(contract));
  const abiSource = fs.readFileSync(
    `../artifacts/contracts/${contract}.sol/${filename}.json`,
    "utf-8",
  );
  fs.writeFileSync(
    `../../gaiawar-interface/game/contracts/artifacts/${filename}.json`,
    abiSource,
  );
}
