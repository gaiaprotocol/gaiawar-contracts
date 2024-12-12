import { expect } from "chai";
import { ethers } from "hardhat";
import { UnitManager, UnitManager__factory } from "../typechain-types";

describe("UnitManager", function () {
  let UnitManagerFactory: UnitManager__factory;
  let unitManager: UnitManager;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    UnitManagerFactory =
      (await ethers.getContractFactory("UnitManager")) as UnitManager__factory;
    [owner, addr1] = await ethers.getSigners();
    unitManager = (await UnitManagerFactory.deploy()) as UnitManager;
    await unitManager.initialize();
  });

  it("should allow the owner to add a unit", async function () {
    const hp = 100;
    const damage = 50;
    const attackRange = 1;
    const assetVersion = 1;
    const trainCosts = [100];
    const preUpgradeUnitId = 0;
    const upgradeItemId = 0;

    await expect(
      unitManager.addUnit(
        hp,
        damage,
        attackRange,
        assetVersion,
        trainCosts,
        preUpgradeUnitId,
        upgradeItemId,
      ),
    )
      .to.emit(unitManager, "UnitAdded")
      .withArgs(
        1,
        hp,
        damage,
        attackRange,
        assetVersion,
        trainCosts,
        preUpgradeUnitId,
        upgradeItemId,
      );

    const unit = await unitManager.getUnit(1);
    expect(unit.hp).to.equal(hp);
    expect(unit.damage).to.equal(damage);
  });

  it("should not allow non-owner to add a unit", async function () {
    await expect(
      unitManager.connect(addr1).addUnit(100, 50, 1, 1, [100], 0, 0),
    ).to.be.revertedWithCustomError(unitManager, "OwnableUnauthorizedAccount");
  });
});
