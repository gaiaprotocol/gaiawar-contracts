import { expect } from "chai";
import { ethers } from "hardhat";
import { UnitRegistry, UnitRegistry__factory } from "../typechain-types";

describe("UnitRegistry", function () {
  let UnitRegistryFactory: UnitRegistry__factory;
  let unitRegistry: UnitRegistry;
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    UnitRegistryFactory = (await ethers.getContractFactory(
      "UnitRegistry",
    )) as UnitRegistry__factory;
    [owner, addr1, addr2] = await ethers.getSigners();
    unitRegistry = (await UnitRegistryFactory.deploy()) as UnitRegistry;
    await unitRegistry.initialize();
  });

  describe("Initialization", function () {
    it("should set the deployer as the owner", async function () {
      expect(await unitRegistry.owner()).to.equal(owner.address);
    });
  });

  describe("Unit Management", function () {
    it("should allow the owner to add a unit", async function () {
      const hp = 100;
      const damage = 50;
      const attackRange = 1;
      const assetVersion = 1;
      const trainCosts = [100, 200];
      const preUpgradeUnitId = 0;
      const upgradeItemId = 0;

      await expect(unitRegistry.addUnit(
        hp,
        damage,
        attackRange,
        assetVersion,
        trainCosts,
        preUpgradeUnitId,
        upgradeItemId,
      ))
        .to.emit(unitRegistry, "UnitAdded")
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

      const unit = await unitRegistry.getUnit(1);
      expect(unit.hp).to.equal(hp);
      expect(unit.damage).to.equal(damage);
      expect(unit.attackRange).to.equal(attackRange);
      expect(unit.assetVersion).to.equal(assetVersion);
      expect(unit.trainCosts).to.deep.equal(trainCosts);
      expect(unit.preUpgradeUnitId).to.equal(preUpgradeUnitId);
      expect(unit.upgradeItemId).to.equal(upgradeItemId);
    });

    it("should not allow non-owner to add a unit", async function () {
      await expect(
        unitRegistry.connect(addr1).addUnit(100, 50, 1, 1, [100], 0, 0),
      ).to.be.revertedWithCustomError(
        unitRegistry,
        "OwnableUnauthorizedAccount",
      );
    });

    it("should not allow adding a unit with an existing ID", async function () {
      await unitRegistry.addUnit(100, 50, 1, 1, [100], 0, 0);
      await expect(
        unitRegistry.addUnit(200, 75, 2, 2, [200], 0, 0),
      ).to.not.be.reverted;

      await expect(
        unitRegistry.addUnit(300, 100, 3, 3, [300], 0, 0),
      ).to.not.be.reverted;
    });

    it("should correctly handle unit upgrades", async function () {
      await unitRegistry.addUnit(100, 50, 1, 1, [100], 0, 0);
      await unitRegistry.addUnit(150, 75, 2, 2, [200], 1, 1);

      const baseUnit = await unitRegistry.getUnit(1);
      const upgradedUnit = await unitRegistry.getUnit(2);

      expect(upgradedUnit.preUpgradeUnitId).to.equal(1);
      expect(upgradedUnit.hp).to.be.gt(baseUnit.hp);
      expect(upgradedUnit.damage).to.be.gt(baseUnit.damage);
    });
  });

  describe("Unit Retrieval", function () {
    beforeEach(async function () {
      await unitRegistry.addUnit(100, 50, 1, 1, [100], 0, 0);
    });

    it("should correctly retrieve an existing unit", async function () {
      const unit = await unitRegistry.getUnit(1);
      expect(unit.hp).to.equal(100);
      expect(unit.damage).to.equal(50);
    });

    it("should return default values for a non-existent unit", async function () {
      const unit = await unitRegistry.getUnit(999);
      expect(unit.hp).to.equal(0);
      expect(unit.damage).to.equal(0);
      expect(unit.attackRange).to.equal(0);
      expect(unit.assetVersion).to.equal(0);
      expect(unit.trainCosts).to.deep.equal([]);
      expect(unit.preUpgradeUnitId).to.equal(0);
      expect(unit.upgradeItemId).to.equal(0);
    });
  });

  describe("Edge Cases", function () {
    it("should handle adding a unit with zero HP and damage", async function () {
      await expect(unitRegistry.addUnit(0, 0, 0, 1, [], 0, 0))
        .to.emit(unitRegistry, "UnitAdded")
        .withArgs(1, 0, 0, 0, 1, [], 0, 0);

      const unit = await unitRegistry.getUnit(1);
      expect(unit.hp).to.equal(0);
      expect(unit.damage).to.equal(0);
    });

    it("should handle adding a unit with empty train costs", async function () {
      await unitRegistry.addUnit(100, 50, 1, 1, [], 0, 0);
      const unit = await unitRegistry.getUnit(1);
      expect(unit.trainCosts).to.deep.equal([]);
    });

    it("should handle adding a unit with maximum possible values", async function () {
      const maxUint16 = 65535;
      const maxUint8 = 255;
      await expect(
        unitRegistry.addUnit(
          maxUint16,
          maxUint16,
          maxUint8,
          maxUint16,
          [ethers.MaxUint256],
          maxUint16,
          maxUint16,
        ),
      )
        .to.emit(unitRegistry, "UnitAdded")
        .withArgs(
          1,
          maxUint16,
          maxUint16,
          maxUint8,
          maxUint16,
          [ethers.MaxUint256],
          maxUint16,
          maxUint16,
        );

      const unit = await unitRegistry.getUnit(1);
      expect(unit.hp).to.equal(maxUint16);
      expect(unit.damage).to.equal(maxUint16);
      expect(unit.attackRange).to.equal(maxUint8);
    });
  });
});
