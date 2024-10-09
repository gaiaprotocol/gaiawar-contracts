import { expect } from "chai";
import { ethers } from "hardhat";
import {
  AssetManager,
  AssetManager__factory,
  BuildingManager,
  BuildingManager__factory,
  GaiaWar,
  GaiaWar__factory,
  TestERC1155,
  TestERC1155__factory,
  TestERC20,
  TestERC20__factory,
  UnitManager,
  UnitManager__factory,
} from "../typechain-types";

describe("GaiaWar Comprehensive Tests", function () {
  let GaiaWarFactory: GaiaWar__factory;
  let gaiaWar: GaiaWar;
  let AssetManagerFactory: AssetManager__factory;
  let assetManager: AssetManager;
  let BuildingManagerFactory: BuildingManager__factory;
  let buildingManager: BuildingManager;
  let UnitManagerFactory: UnitManager__factory;
  let unitManager: UnitManager;
  let TestERC20Factory: TestERC20__factory;
  let testToken: TestERC20;
  let TestERC1155Factory: TestERC1155__factory;
  let testItem: TestERC1155;
  let owner: any;
  let player1: any;
  let player2: any;
  let player3: any;

  beforeEach(async function () {
    [owner, player1, player2, player3] = await ethers.getSigners();

    // Deploy TestERC20 (ERC20 Token)
    TestERC20Factory = (await ethers.getContractFactory(
      "TestERC20",
    )) as TestERC20__factory;
    testToken = (await TestERC20Factory.deploy(
      "Test Token",
      "TST",
    )) as TestERC20;
    await testToken.waitForDeployment();

    // Deploy TestERC1155 (ERC1155 Item)
    TestERC1155Factory = (await ethers.getContractFactory(
      "TestERC1155",
    )) as TestERC1155__factory;
    testItem = (await TestERC1155Factory.deploy()) as TestERC1155;
    await testItem.waitForDeployment();

    // Deploy and initialize AssetManager
    AssetManagerFactory = (await ethers.getContractFactory(
      "AssetManager",
    )) as AssetManager__factory;
    assetManager = (await AssetManagerFactory.deploy()) as AssetManager;
    await assetManager.waitForDeployment();
    await assetManager.initialize();

    // Deploy and initialize BuildingManager
    BuildingManagerFactory = (await ethers.getContractFactory(
      "BuildingManager",
    )) as BuildingManager__factory;
    buildingManager =
      (await BuildingManagerFactory.deploy()) as BuildingManager;
    await buildingManager.waitForDeployment();
    await buildingManager.initialize();

    // Deploy and initialize UnitManager
    UnitManagerFactory = (await ethers.getContractFactory(
      "UnitManager",
    )) as UnitManager__factory;
    unitManager = (await UnitManagerFactory.deploy()) as UnitManager;
    await unitManager.waitForDeployment();
    await unitManager.initialize();

    // Deploy and initialize GaiaWar
    GaiaWarFactory = (await ethers.getContractFactory(
      "GaiaWar",
    )) as GaiaWar__factory;
    gaiaWar = (await GaiaWarFactory.deploy()) as GaiaWar;
    await gaiaWar.waitForDeployment();
    await gaiaWar.initialize(
      assetManager.target,
      buildingManager.target,
      unitManager.target,
      20, // mapRows
      20, // mapCols
      100, // maxUnitsPerTile
      5, // maxUnitMovementRange
      10, // ownerSharePercentage
    );
  });

  describe("Contract Initialization", function () {
    it("should initialize GaiaWar contract correctly", async function () {
      expect(await gaiaWar.assetManager()).to.equal(assetManager.target);
      expect(await gaiaWar.buildingManager()).to.equal(buildingManager.target);
      expect(await gaiaWar.unitManager()).to.equal(unitManager.target);
      expect(await gaiaWar.mapRows()).to.equal(20);
      expect(await gaiaWar.mapCols()).to.equal(20);
      expect(await gaiaWar.maxUnitsPerTile()).to.equal(100);
      expect(await gaiaWar.maxUnitMovementRange()).to.equal(5);
      expect(await gaiaWar.ownerSharePercentage()).to.equal(10);
    });

    it("should initialize AssetManager correctly", async function () {
      expect(await assetManager.currentVersion()).to.equal(0);
    });

    it("should initialize BuildingManager correctly", async function () {
      // nextBuildingId should be 1
      // Since nextBuildingId is private, we can test by adding a building
      await buildingManager.addBuilding(0, 1, [100], true);
      const building = await buildingManager.getBuilding(1);
      expect(building.level).to.equal(1);
    });

    it("should initialize UnitManager correctly", async function () {
      // nextUnitId should be 1
      await unitManager.addUnit(100, 50, 1, 1, [100], 0, 0);
      const unit = await unitManager.getUnit(1);
      expect(unit.hp).to.equal(100);
    });
  });

  describe("Asset and Unit Setup", function () {
    beforeEach(async function () {
      // Add an asset with testToken as resource and testItem as item
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint ERC20 tokens to players
      await testToken.mint(player1.target, ethers.parseEther("10000"));
      await testToken.mint(player2.target, ethers.parseEther("10000"));
      await testToken.mint(player3.target, ethers.parseEther("10000"));

      // Players approve GaiaWar to spend their tokens
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);
      await testToken
        .connect(player2)
        .approve(gaiaWar.target, ethers.MaxUint256);
      await testToken
        .connect(player3)
        .approve(gaiaWar.target, ethers.MaxUint256);

      // Mint ERC1155 items to players
      await testItem.mint(player1.target, 1, 1000, "0x");
      await testItem.mint(player2.target, 1, 1000, "0x");
      await testItem.mint(player3.target, 1, 1000, "0x");

      // Players set approval for GaiaWar to handle their items
      await testItem
        .connect(player1)
        .setApprovalForAll(gaiaWar.target, true);
      await testItem
        .connect(player2)
        .setApprovalForAll(gaiaWar.target, true);
      await testItem
        .connect(player3)
        .setApprovalForAll(gaiaWar.target, true);

      // Add units to UnitManager
      // Basic unit
      await unitManager.addUnit(
        100, // hp
        50, // damage
        1, // attackRange
        1, // assetVersion
        [ethers.parseEther("100")], // trainCosts
        0, // preUpgradeUnitId
        0, // upgradeItemId
      );

      // Upgraded unit
      await unitManager.addUnit(
        200, // hp
        100, // damage
        1, // attackRange
        1, // assetVersion
        [ethers.parseEther("200")], // trainCosts
        1, // preUpgradeUnitId
        1, // upgradeItemId
      );

      // Add buildings to BuildingManager
      // Headquarters
      await buildingManager.addBuilding(
        0, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("500")], // constructionCosts
        true, // isHeadquarters
      );

      // Advanced building
      await buildingManager.addBuilding(
        1, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("1000")], // constructionCosts
        false, // isHeadquarters
      );

      // Assign producible units to buildings
      await buildingManager.addProducibleUnits(1, [1]); // Building 1 can produce unit 1
      await buildingManager.addProducibleUnits(2, [2]); // Building 2 can produce unit 2
    });

    it("should correctly setup assets, units, and buildings", async function () {
      // Verify AssetManager
      const assetVersion = await assetManager.currentVersion();
      expect(assetVersion).to.equal(1);
      const asset = await assetManager.getAsset(1);
      expect(asset.resources[0]).to.equal(testToken.target);
      expect(asset.item).to.equal(testItem.target);

      // Verify UnitManager
      const unit1 = await unitManager.getUnit(1);
      expect(unit1.hp).to.equal(100);
      expect(unit1.damage).to.equal(50);

      const unit2 = await unitManager.getUnit(2);
      expect(unit2.hp).to.equal(200);
      expect(unit2.damage).to.equal(100);
      expect(unit2.preUpgradeUnitId).to.equal(1);
      expect(unit2.upgradeItemId).to.equal(1);

      // Verify BuildingManager
      const building1 = await buildingManager.getBuilding(1);
      expect(building1.isHeadquarters).to.be.true;

      const building2 = await buildingManager.getBuilding(2);
      expect(building2.isHeadquarters).to.be.false;
      expect(building2.preUpgradeBuildingId).to.equal(1);

      // Verify producible units
      const canProduceUnit1 = await buildingManager.canProduceUnit(1, 1);
      expect(canProduceUnit1).to.be.true;

      const canProduceUnit2 = await buildingManager.canProduceUnit(2, 2);
      expect(canProduceUnit2).to.be.true;
    });
  });

  describe("Building Construction and Upgrading", function () {
    beforeEach(async function () {
      // Setup from previous tests
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens and approve GaiaWar
      await testToken.mint(player1.target, ethers.parseEther("10000"));
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);

      // Add buildings
      await buildingManager.addBuilding(
        0,
        1,
        [ethers.parseEther("500")],
        true,
      );

      await buildingManager.addBuilding(
        1,
        1,
        [ethers.parseEther("1000")],
        false,
      );
    });

    it("should allow player to build headquarters", async function () {
      await expect(
        gaiaWar.connect(player1).buildBuilding(5, 5, 1),
      )
        .to.emit(gaiaWar, "BuildingConstructed")
        .withArgs(player1.target, 5, 5, 1);

      const tile = await gaiaWar.map(5, 5);
      expect(tile.occupant).to.equal(player1.target);
      expect(tile.buildingId).to.equal(1);
    });

    it("should prevent building near enemy headquarters", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Player2 attempts to build near player1's headquarters
      await testToken.mint(player2.target, ethers.parseEther("10000"));
      await testToken
        .connect(player2)
        .approve(gaiaWar.target, ethers.MaxUint256);

      await expect(
        gaiaWar.connect(player2).buildBuilding(7, 5, 1),
      ).to.be.revertedWith("Cannot build near enemy building");
    });

    it("should allow building upgrade", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Upgrade to buildingId 2
      await expect(
        gaiaWar.connect(player1).upgradeBuilding(5, 5, 2),
      )
        .to.emit(gaiaWar, "BuildingConstructed")
        .withArgs(player1.target, 5, 5, 2);

      const tile = await gaiaWar.map(5, 5);
      expect(tile.buildingId).to.equal(2);
    });

    it("should not allow invalid building upgrade", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Attempt invalid upgrade
      await expect(
        gaiaWar.connect(player1).upgradeBuilding(5, 5, 3),
      ).to.be.revertedWith("Invalid upgrade path");
    });
  });

  describe("Unit Training and Upgrading", function () {
    beforeEach(async function () {
      // Setup from previous tests
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens and items
      await testToken.mint(player1.target, ethers.parseEther("10000"));
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);

      await testItem.mint(player1.target, 1, 1000, "0x");
      await testItem
        .connect(player1)
        .setApprovalForAll(gaiaWar.target, true);

      // Add units
      await unitManager.addUnit(
        100,
        50,
        1,
        1,
        [ethers.parseEther("100")],
        0,
        0,
      );

      await unitManager.addUnit(
        200,
        100,
        1,
        1,
        [ethers.parseEther("200")],
        1,
        1,
      );

      // Add building and assign producible units
      await buildingManager.addBuilding(
        0,
        1,
        [ethers.parseEther("500")],
        true,
      );

      await buildingManager.addProducibleUnits(1, [1]);

      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
    });

    it("should allow unit training", async function () {
      await expect(
        gaiaWar.connect(player1).trainUnits(5, 5, 1, 10),
      )
        .to.emit(gaiaWar, "UnitsTrained")
        .withArgs(player1.target, 5, 5, 1, 10);

      const units = await gaiaWar.getTileUnits(5, 5);
      expect(units.length).to.equal(1);
      expect(units[0].unitId).to.equal(1);
      expect(units[0].amount).to.equal(10);
    });

    it("should prevent training units exceeding max units per tile", async function () {
      await expect(
        gaiaWar.connect(player1).trainUnits(5, 5, 1, 101),
      ).to.be.revertedWith("Exceeds max units per tile");
    });

    it("should allow unit upgrading", async function () {
      // Train basic units
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Upgrade units to unitId 2
      await expect(
        gaiaWar.connect(player1).upgradeUnits(5, 5, 2, 5),
      )
        .to.emit(gaiaWar, "UnitsUpgraded")
        .withArgs(player1.target, 5, 5, 2, 5);

      const units = await gaiaWar.getTileUnits(5, 5);
      expect(units.length).to.equal(2);

      const unit1 = units.find((u) => u.unitId === 1n);
      const unit2 = units.find((u) => u.unitId === 2n);

      expect(unit1?.amount).to.equal(5);
      expect(unit2?.amount).to.equal(5);
    });

    it("should not allow unit upgrading without required items", async function () {
      // Transfer all items from player1 to player2
      await testItem
        .connect(player1)
        .safeTransferFrom(player1.target, player2.target, 1, 1000, "0x");

      // Train basic units
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Attempt to upgrade units without items
      await expect(
        gaiaWar.connect(player1).upgradeUnits(5, 5, 2, 5),
      ).to.be.revertedWith("ERC1155: insufficient balance for transfer");
    });
  });

  describe("Unit Movement and Combat", function () {
    beforeEach(async function () {
      // Setup from previous tests
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens
      await testToken.mint(player1.target, ethers.parseEther("10000"));
      await testToken.mint(player2.target, ethers.parseEther("10000"));
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);
      await testToken
        .connect(player2)
        .approve(gaiaWar.target, ethers.MaxUint256);

      // Add units and buildings
      await unitManager.addUnit(
        100,
        50,
        1,
        1,
        [ethers.parseEther("100")],
        0,
        0,
      );

      await buildingManager.addBuilding(
        0,
        1,
        [ethers.parseEther("500")],
        true,
      );

      await buildingManager.addProducibleUnits(1, [1]);

      // Player1 builds headquarters at (5,5) and trains units
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 50);

      // Player2 builds headquarters at (10,10) and trains units
      await gaiaWar.connect(player2).buildBuilding(10, 10, 1);
      await gaiaWar.connect(player2).trainUnits(10, 10, 1, 30);
    });

    it("should allow unit movement within movement range", async function () {
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 8, 8, [{ unitId: 1, amount: 20 }]),
      )
        .to.emit(gaiaWar, "UnitsMoved")
        .withArgs(5, 5, 8, 8, [[1n, 20n]]);

      const unitsAtDestination = await gaiaWar.getTileUnits(8, 8);
      expect(unitsAtDestination.length).to.equal(1);
      expect(unitsAtDestination[0].unitId).to.equal(1);
      expect(unitsAtDestination[0].amount).to.equal(20);
    });

    it("should prevent unit movement exceeding movement range", async function () {
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 15, 15, [{ unitId: 1, amount: 20 }]),
      ).to.be.revertedWith("Movement range exceeded");
    });

    it("should enforce max units per tile when moving units", async function () {
      // Move units to a tile
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 50 }]);

      // Train more units at headquarters
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 60);

      // Attempt to move units exceeding maxUnitsPerTile to the same tile
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 60 }]),
      ).to.be.revertedWith("Exceeds max units per tile");
    });

    it("should allow combat between players", async function () {
      // Player1 moves units close to Player2
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 8, 8, [{ unitId: 1, amount: 50 }]);

      // Player1 attacks Player2
      await expect(
        gaiaWar.connect(player1).attack(8, 8, 10, 10),
      ).to.emit(gaiaWar, "AttackResult");

      const tile = await gaiaWar.map(10, 10);
      expect(tile.occupant).to.equal(player1.target);
    });

    it("should handle combat where defender wins", async function () {
      // Player2 trains more units
      await gaiaWar.connect(player2).trainUnits(10, 10, 1, 100);

      // Player1 moves units close
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 8, 8, [{ unitId: 1, amount: 50 }]);

      // Player1 attacks Player2
      await expect(
        gaiaWar.connect(player1).attack(8, 8, 10, 10),
      ).to.emit(gaiaWar, "AttackResult");

      const tile = await gaiaWar.map(10, 10);
      expect(tile.occupant).to.equal(player2.target);

      // Verify that Player1's units are destroyed
      const fromTileUnits = await gaiaWar.getTileUnits(8, 8);
      expect(fromTileUnits.length).to.equal(0);
    });

    it("should correctly distribute loot after combat", async function () {
      // Player2 builds an advanced building at (10,11)
      await gaiaWar.connect(player2).buildBuilding(10, 11, 2);

      // Player2 trains more units
      await gaiaWar.connect(player2).trainUnits(10, 10, 1, 50);

      // Player1 moves units close
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 10, 9, [{ unitId: 1, amount: 80 }]);

      // Player1 attacks Player2
      await expect(
        gaiaWar.connect(player1).attack(10, 9, 10, 10),
      ).to.emit(gaiaWar, "AttackResult");

      // Check balances after loot distribution
      const ownerBalance = await testToken.balanceOf(owner.target);
      const player1Balance = await testToken.balanceOf(player1.target);

      expect(ownerBalance).to.be.gt(0);
      expect(player1Balance).to.be.gt(0);
    });
  });

  describe("Additional Edge Cases", function () {
    it("should prevent moving units not owned by the player", async function () {
      // Player1 builds headquarters and trains units
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Player2 attempts to move Player1's units
      await expect(
        gaiaWar
          .connect(player2)
          .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 5 }]),
      ).to.be.revertedWith("Not your units");
    });

    it("should prevent attacking own units", async function () {
      // Player1 builds headquarters and trains units
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Player1 attempts to attack own units
      await expect(
        gaiaWar.connect(player1).attack(5, 5, 5, 5),
      ).to.be.revertedWith("Cannot attack your own units");
    });

    it("should prevent constructing multiple headquarters", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Attempt to build another headquarters
      await expect(
        gaiaWar.connect(player1).buildBuilding(6, 6, 1),
      ).to.be.revertedWith("Cannot build near enemy building");
    });

    it("should prevent building outside of allowed range", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Attempt to build a building outside of allowed range
      await expect(
        gaiaWar.connect(player1).buildBuilding(20, 20, 2),
      ).to.be.revertedWith("Cannot build outside of allowed range");
    });
  });
});
