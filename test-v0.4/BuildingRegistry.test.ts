import { expect } from "chai";
import { ethers } from "hardhat";
import {
  BuildingRegistry,
  BuildingRegistry__factory,
} from "../typechain-types";

describe("BuildingRegistry", function () {
  let BuildingRegistryFactory: BuildingRegistry__factory;
  let buildingRegistry: BuildingRegistry;
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    BuildingRegistryFactory = (await ethers.getContractFactory(
      "BuildingRegistry",
    )) as BuildingRegistry__factory;
    [owner, addr1, addr2] = await ethers.getSigners();
    buildingRegistry =
      (await BuildingRegistryFactory.deploy()) as BuildingRegistry;
    await buildingRegistry.initialize();
  });

  describe("Initialization", function () {
    it("should set the deployer as the owner", async function () {
      expect(await buildingRegistry.owner()).to.equal(owner.address);
    });
  });

  describe("Building Management", function () {
    it("should allow the owner to add a building", async function () {
      const preUpgradeBuildingId = 0;
      const assetVersion = 1;
      const constructionCosts = [100, 200];
      const isHeadquarters = true;

      await expect(buildingRegistry.addBuilding(
        preUpgradeBuildingId,
        assetVersion,
        constructionCosts,
        isHeadquarters,
      ))
        .to.emit(buildingRegistry, "BuildingAdded")
        .withArgs(
          1,
          assetVersion,
          preUpgradeBuildingId,
          constructionCosts,
          isHeadquarters,
        );

      const building = await buildingRegistry.getBuilding(1);
      expect(building.level).to.equal(1);
      expect(building.isHeadquarters).to.equal(true);
      expect(building.assetVersion).to.equal(assetVersion);
      expect(building.constructionCosts).to.deep.equal(constructionCosts);
    });

    it("should not allow non-owner to add a building", async function () {
      await expect(
        buildingRegistry.connect(addr1).addBuilding(0, 1, [], false),
      ).to.be.revertedWithCustomError(
        buildingRegistry,
        "OwnableUnauthorizedAccount",
      );
    });

    it("should correctly set building level based on preUpgradeBuildingId", async function () {
      await buildingRegistry.addBuilding(0, 1, [100], false);
      await buildingRegistry.addBuilding(1, 2, [200], false);

      const building1 = await buildingRegistry.getBuilding(1);
      const building2 = await buildingRegistry.getBuilding(2);

      expect(building1.level).to.equal(1);
      expect(building2.level).to.equal(2);
    });
  });

  describe("Producible Units Management", function () {
    beforeEach(async function () {
      await buildingRegistry.addBuilding(0, 1, [100], false);
    });

    it("should correctly manage producible units", async function () {
      await buildingRegistry.addProducibleUnits(1, [1, 2]);

      expect(await buildingRegistry.canProduceUnit(1, 1)).to.equal(true);
      expect(await buildingRegistry.canProduceUnit(1, 2)).to.equal(true);
      expect(await buildingRegistry.canProduceUnit(1, 3)).to.equal(false);

      await buildingRegistry.removeProducibleUnits(1, [1]);

      expect(await buildingRegistry.canProduceUnit(1, 1)).to.equal(false);
      expect(await buildingRegistry.canProduceUnit(1, 2)).to.equal(true);
    });

    it("should not allow non-owner to add producible units", async function () {
      await expect(
        buildingRegistry.connect(addr1).addProducibleUnits(1, [1, 2]),
      ).to.be.revertedWithCustomError(
        buildingRegistry,
        "OwnableUnauthorizedAccount",
      );
    });

    it("should not allow non-owner to remove producible units", async function () {
      await buildingRegistry.addProducibleUnits(1, [1, 2]);
      await expect(
        buildingRegistry.connect(addr1).removeProducibleUnits(1, [1]),
      ).to.be.revertedWithCustomError(
        buildingRegistry,
        "OwnableUnauthorizedAccount",
      );
    });

    it("should handle adding and removing producible units for non-existent buildings", async function () {
      await buildingRegistry.addProducibleUnits(999, [1, 2]);
      expect(await buildingRegistry.canProduceUnit(999, 1)).to.equal(true);

      await buildingRegistry.removeProducibleUnits(999, [1]);
      expect(await buildingRegistry.canProduceUnit(999, 1)).to.equal(false);
    });
  });

  describe("Edge Cases", function () {
    it("should handle getting a non-existent building", async function () {
      const building = await buildingRegistry.getBuilding(999);
      expect(building.level).to.equal(0);
      expect(building.isHeadquarters).to.equal(false);
      expect(building.assetVersion).to.equal(0);
      expect(building.constructionCosts).to.deep.equal([]);
    });

    it("should handle adding a building with empty construction costs", async function () {
      await buildingRegistry.addBuilding(0, 1, [], false);
      const building = await buildingRegistry.getBuilding(1);
      expect(building.constructionCosts).to.deep.equal([]);
    });

    it("should handle adding and removing an empty list of producible units", async function () {
      await buildingRegistry.addBuilding(0, 1, [100], false);
      await buildingRegistry.addProducibleUnits(1, []);
      await buildingRegistry.removeProducibleUnits(1, []);
      expect(await buildingRegistry.canProduceUnit(1, 1)).to.equal(false);
    });
  });
});
