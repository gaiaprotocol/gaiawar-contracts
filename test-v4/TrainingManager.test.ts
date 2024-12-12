import { expect } from "chai";
import { ethers } from "hardhat";
import {
  AssetRegistry,
  AssetRegistry__factory,
  BuildingRegistry,
  BuildingRegistry__factory,
  MockMapStorage,
  MockMapStorage__factory,
  TestERC1155,
  TestERC1155__factory,
  TestERC20,
  TestERC20__factory,
  TrainingManager,
  TrainingManager__factory,
  UnitRegistry,
  UnitRegistry__factory,
} from "../typechain-types";

describe("TrainingManager", function () {
  let trainingManager: TrainingManager;
  let assetRegistry: AssetRegistry;
  let unitRegistry: UnitRegistry;
  let buildingRegistry: BuildingRegistry;
  let mapStorage: MockMapStorage;
  let testToken: TestERC20;
  let testItem: TestERC1155;
  let owner: any;
  let player1: any;
  let player2: any;

  beforeEach(async function () {
    [owner, player1, player2] = await ethers.getSigners();

    // Deploy TestERC20
    const TestERC20Factory = await ethers.getContractFactory(
      "TestERC20",
    ) as TestERC20__factory;
    testToken = await TestERC20Factory.deploy("Test Token", "TST");

    // Deploy TestERC1155
    const TestERC1155Factory = await ethers.getContractFactory(
      "TestERC1155",
    ) as TestERC1155__factory;
    testItem = await TestERC1155Factory.deploy();

    // Deploy and initialize AssetRegistry
    const AssetRegistryFactory = await ethers.getContractFactory(
      "AssetRegistry",
    ) as AssetRegistry__factory;
    assetRegistry = await AssetRegistryFactory.deploy();
    await assetRegistry.initialize();

    // Deploy and initialize UnitRegistry
    const UnitRegistryFactory = await ethers.getContractFactory(
      "UnitRegistry",
    ) as UnitRegistry__factory;
    unitRegistry = await UnitRegistryFactory.deploy();
    await unitRegistry.initialize();

    // Deploy and initialize BuildingRegistry
    const BuildingRegistryFactory = await ethers.getContractFactory(
      "BuildingRegistry",
    ) as BuildingRegistry__factory;
    buildingRegistry = await BuildingRegistryFactory.deploy();
    await buildingRegistry.initialize();

    // Deploy MockMapStorage
    const MockMapStorageFactory = await ethers.getContractFactory(
      "MockMapStorage",
    ) as MockMapStorage__factory;
    mapStorage = await MockMapStorageFactory.deploy();

    // Deploy and initialize TrainingManager
    const TrainingManagerFactory = await ethers.getContractFactory(
      "TrainingManager",
    ) as TrainingManager__factory;
    trainingManager = await TrainingManagerFactory.deploy();
    await trainingManager.initialize(
      assetRegistry.target,
      unitRegistry.target,
      buildingRegistry.target,
      mapStorage.target,
    );

    // Add asset to AssetRegistry
    await assetRegistry.addAsset([testToken.target], testItem.target);

    // Add units to UnitRegistry
    await unitRegistry.addUnit(100, 50, 1, 1, [ethers.parseEther("100")], 0, 0); // Basic unit
    await unitRegistry.addUnit(
      200,
      100,
      1,
      1,
      [ethers.parseEther("200")],
      1,
      1,
    ); // Upgraded unit

    // Add buildings to BuildingRegistry
    await buildingRegistry.addBuilding(0, 1, [ethers.parseEther("500")], true);
    await buildingRegistry.addProducibleUnits(1, [1, 2]);

    // Mint tokens to players and approve TrainingManager
    await testToken.mint(player1.address, ethers.parseEther("10000"));
    await testToken.mint(player2.address, ethers.parseEther("10000"));
    await testToken.connect(player1).approve(
      trainingManager.target,
      ethers.MaxUint256,
    );
    await testToken.connect(player2).approve(
      trainingManager.target,
      ethers.MaxUint256,
    );

    // Mint upgrade items to players
    await testItem.mint(player1.address, 1, 1000, "0x");
    await testItem.mint(player2.address, 1, 1000, "0x");
    await testItem.connect(player1).setApprovalForAll(
      trainingManager.target,
      true,
    );
    await testItem.connect(player2).setApprovalForAll(
      trainingManager.target,
      true,
    );

    // Setup initial map state
    await mapStorage.setTileOccupant(5, 5, player1.address);
    await mapStorage.setTileBuildingId(5, 5, 1);
  });

  describe("Initialization", function () {
    it("should initialize with correct values", async function () {
      expect(await trainingManager.assetRegistry()).to.equal(
        assetRegistry.target,
      );
      expect(await trainingManager.unitRegistry()).to.equal(
        unitRegistry.target,
      );
      expect(await trainingManager.buildingRegistry()).to.equal(
        buildingRegistry.target,
      );
      expect(await trainingManager.mapStorage()).to.equal(mapStorage.target);
    });
  });

  describe("Unit Training", function () {
    it("should allow player to train units", async function () {
      await expect(trainingManager.connect(player1).trainUnits(5, 5, 1, 10))
        .to.emit(trainingManager, "UnitsTrained")
        .withArgs(player1.address, 5, 5, 1, 10);

      const tileUnits = await mapStorage.getTileUnits(5, 5);
      expect(tileUnits.length).to.equal(1);
      expect(tileUnits[0].unitId).to.equal(1);
      expect(tileUnits[0].amount).to.equal(10);
    });

    it("should deduct resources when training units", async function () {
      const initialBalance = await testToken.balanceOf(player1.address);
      await trainingManager.connect(player1).trainUnits(5, 5, 1, 10);
      const finalBalance = await testToken.balanceOf(player1.address);
      expect(initialBalance - finalBalance).to.equal(ethers.parseEther("1000")); // 10 units * 100 cost
    });

    it("should not allow training units on tiles not owned by the player", async function () {
      await mapStorage.setTileOccupant(5, 5, player2.address);
      await expect(trainingManager.connect(player1).trainUnits(5, 5, 1, 10))
        .to.be.revertedWith("Not your tile");
    });

    it("should not allow training units that the building cannot produce", async function () {
      await buildingRegistry.removeProducibleUnits(1, [1]);
      await expect(trainingManager.connect(player1).trainUnits(5, 5, 1, 10))
        .to.be.revertedWith("Building cannot produce this unit");
    });

    it("should not allow training units when player lacks resources", async function () {
      await testToken.connect(player1).transfer(
        player2.address,
        await testToken.balanceOf(player1.address),
      );
      await expect(trainingManager.connect(player1).trainUnits(5, 5, 1, 10))
        .to.be.reverted; // The exact error message may vary depending on the ERC20 implementation
    });
  });

  describe("Unit Upgrading", function () {
    beforeEach(async function () {
      // Train some basic units first
      await trainingManager.connect(player1).trainUnits(5, 5, 1, 20);
    });

    it("should allow player to upgrade units", async function () {
      await expect(trainingManager.connect(player1).upgradeUnits(5, 5, 2, 10))
        .to.emit(trainingManager, "UnitsUpgraded")
        .withArgs(player1.address, 5, 5, 2, 10);

      const tileUnits = await mapStorage.getTileUnits(5, 5);
      expect(tileUnits.length).to.equal(2);
      expect(tileUnits[0].unitId).to.equal(1);
      expect(tileUnits[0].amount).to.equal(10);
      expect(tileUnits[1].unitId).to.equal(2);
      expect(tileUnits[1].amount).to.equal(10);
    });

    it("should consume upgrade items when upgrading units", async function () {
      const initialBalance = await testItem.balanceOf(player1.address, 1);
      await trainingManager.connect(player1).upgradeUnits(5, 5, 2, 10);
      const finalBalance = await testItem.balanceOf(player1.address, 1);
      expect(initialBalance - finalBalance).to.equal(10);
    });

    it("should not allow upgrading units on tiles not owned by the player", async function () {
      await mapStorage.setTileOccupant(5, 5, player2.address);
      await expect(trainingManager.connect(player1).upgradeUnits(5, 5, 2, 10))
        .to.be.revertedWith("Not your tile");
    });

    it("should not allow upgrading units that don't exist on the tile", async function () {
      await expect(trainingManager.connect(player1).upgradeUnits(5, 5, 3, 10))
        .to.be.revertedWith("Unit cannot be upgraded");
    });

    it("should not allow upgrading more units than available", async function () {
      await expect(trainingManager.connect(player1).upgradeUnits(5, 5, 2, 30))
        .to.be.revertedWith("Not enough units to upgrade");
    });

    it("should not allow upgrading when player lacks upgrade items", async function () {
      await testItem.connect(player1).safeTransferFrom(
        player1.address,
        player2.address,
        1,
        1000,
        "0x",
      );
      await expect(trainingManager.connect(player1).upgradeUnits(5, 5, 2, 10))
        .to.be.reverted; // The exact error message may vary depending on the ERC1155 implementation
    });
  });

  describe("Admin Functions", function () {
    it("should allow owner to set new AssetRegistry", async function () {
      const newAssetRegistry = await (new AssetRegistry__factory(owner))
        .deploy();
      await expect(trainingManager.setAssetRegistry(newAssetRegistry.target))
        .to.emit(trainingManager, "AssetRegistrySet")
        .withArgs(newAssetRegistry.target);
      expect(await trainingManager.assetRegistry()).to.equal(
        newAssetRegistry.target,
      );
    });

    it("should allow owner to set new UnitRegistry", async function () {
      const newUnitRegistry = await (new UnitRegistry__factory(owner)).deploy();
      await expect(trainingManager.setUnitRegistry(newUnitRegistry.target))
        .to.emit(trainingManager, "UnitRegistrySet")
        .withArgs(newUnitRegistry.target);
      expect(await trainingManager.unitRegistry()).to.equal(
        newUnitRegistry.target,
      );
    });

    it("should allow owner to set new BuildingRegistry", async function () {
      const newBuildingRegistry = await (new BuildingRegistry__factory(owner))
        .deploy();
      await expect(
        trainingManager.setBuildingRegistry(newBuildingRegistry.target),
      )
        .to.emit(trainingManager, "BuildingRegistrySet")
        .withArgs(newBuildingRegistry.target);
      expect(await trainingManager.buildingRegistry()).to.equal(
        newBuildingRegistry.target,
      );
    });

    it("should allow owner to set new MapStorage", async function () {
      const newMapStorage = await (new MockMapStorage__factory(owner)).deploy();
      await expect(trainingManager.setMapStorage(newMapStorage.target))
        .to.emit(trainingManager, "MapStorageSet")
        .withArgs(newMapStorage.target);
      expect(await trainingManager.mapStorage()).to.equal(newMapStorage.target);
    });

    it("should prevent non-owner from setting new registries", async function () {
      const newAssetRegistry = await (new AssetRegistry__factory(owner))
        .deploy();
      await expect(
        trainingManager.connect(player1).setAssetRegistry(
          newAssetRegistry.target,
        ),
      )
        .to.be.revertedWithCustomError(
          trainingManager,
          "OwnableUnauthorizedAccount",
        );
    });
  });
});
