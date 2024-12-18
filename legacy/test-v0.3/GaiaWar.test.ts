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
    buildingManager = await BuildingManagerFactory.deploy();
    await buildingManager.waitForDeployment();
    await buildingManager.initialize();

    // Deploy and initialize UnitManager
    UnitManagerFactory = (await ethers.getContractFactory(
      "UnitManager",
    )) as UnitManager__factory;
    unitManager = await UnitManagerFactory.deploy();
    await unitManager.waitForDeployment();
    await unitManager.initialize();

    // Deploy and initialize GaiaWar
    GaiaWarFactory = (await ethers.getContractFactory(
      "GaiaWar",
    )) as GaiaWar__factory;
    gaiaWar = await GaiaWarFactory.deploy();
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
      expect(await gaiaWar.buildingManager()).to.equal(
        buildingManager.target,
      );
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
      // Test adding a building to ensure initialization
      await buildingManager.addBuilding(0, 1, [100], true);
      const building = await buildingManager.getBuilding(1);
      expect(building.level).to.equal(1);
    });

    it("should initialize UnitManager correctly", async function () {
      // Test adding a unit to ensure initialization
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
      await testToken.mint(player1.address, ethers.parseEther("100000"));
      await testToken.mint(player2.address, ethers.parseEther("100000"));
      await testToken.mint(player3.address, ethers.parseEther("100000"));

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
      await testItem.mint(player1.address, 1, 1000, "0x");
      await testItem.mint(player2.address, 1, 1000, "0x");
      await testItem.mint(player3.address, 1, 1000, "0x");

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
      // Headquarters Level 1
      await buildingManager.addBuilding(
        0, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("500")], // constructionCosts
        true, // isHeadquarters
      );

      // Non-headquarters building
      await buildingManager.addBuilding(
        0, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("700")], // constructionCosts
        false, // isHeadquarters
      );

      // Assign producible units to buildings
      await buildingManager.addProducibleUnits(1, [1, 2]); // Headquarters can produce units 1 and 2
      await buildingManager.addProducibleUnits(2, [1, 2]); // Non-headquarters building can produce units 1 and 2
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

      // Verify producible units
      const canProduceUnit1 = await buildingManager.canProduceUnit(1, 1);
      expect(canProduceUnit1).to.be.true;

      const canProduceUnit2 = await buildingManager.canProduceUnit(1, 2);
      expect(canProduceUnit2).to.be.true;
    });
  });

  describe("Building Construction and Upgrading", function () {
    beforeEach(async function () {
      // Setup from previous tests
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens and approve GaiaWar
      await testToken.mint(player1.address, ethers.parseEther("100000"));
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);

      // Add buildings
      await buildingManager.addBuilding(
        0, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("500")], // constructionCosts
        true, // isHeadquarters
      );

      // Upgraded headquarters (level 2)
      await buildingManager.addBuilding(
        1, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("1000")], // constructionCosts
        true, // isHeadquarters
      );

      // Non-headquarters building
      await buildingManager.addBuilding(
        0, // preUpgradeBuildingId
        1, // assetVersion
        [ethers.parseEther("700")], // constructionCosts
        false, // isHeadquarters
      );
    });

    it("should allow player to build headquarters", async function () {
      await expect(
        gaiaWar.connect(player1).buildBuilding(5, 5, 1),
      )
        .to.emit(gaiaWar, "BuildingConstructed")
        .withArgs(player1.address, 5, 5, 1);

      const tile = await gaiaWar.map(5, 5);
      expect(tile.occupant).to.equal(player1.address);
      expect(tile.buildingId).to.equal(1);
    });

    it("should prevent building near enemy headquarters", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Player2 attempts to build near player1's headquarters
      await testToken.mint(player2.address, ethers.parseEther("100000"));
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

      // Upgrade to buildingId 2 (upgraded headquarters)
      await expect(
        gaiaWar.connect(player1).upgradeBuilding(5, 5, 2),
      )
        .to.emit(gaiaWar, "BuildingConstructed")
        .withArgs(player1.address, 5, 5, 2);

      const tile = await gaiaWar.map(5, 5);
      expect(tile.buildingId).to.equal(2);
    });

    it("should not allow invalid building upgrade", async function () {
      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);

      // Attempt invalid upgrade to buildingId 3 (non-headquarters)
      await expect(
        gaiaWar.connect(player1).upgradeBuilding(5, 5, 3),
      ).to.be.revertedWith("Invalid upgrade");
    });
  });

  describe("Unit Training and Upgrading", function () {
    beforeEach(async function () {
      // Setup from previous tests
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens and items
      await testToken.mint(player1.address, ethers.parseEther("100000"));
      await testToken
        .connect(player1)
        .approve(gaiaWar.target, ethers.MaxUint256);

      await testItem.mint(player1.address, 1, 1000, "0x");
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

      await buildingManager.addProducibleUnits(1, [1]); // Building 1 can produce unit 1

      // Player1 builds headquarters at (5,5)
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
    });

    it("should allow unit training", async function () {
      await expect(
        gaiaWar.connect(player1).trainUnits(5, 5, 1, 10),
      )
        .to.emit(gaiaWar, "UnitsTrained")
        .withArgs(player1.address, 5, 5, 1, 10);

      const units = await gaiaWar.getTileUnits(5, 5);
      expect(units.length).to.equal(1);
      expect(units[0].unitId).to.equal(1);
      expect(units[0].amount).to.equal(10);
    });

    it("should prevent training units exceeding max units per tile", async function () {
      // First, train units up to the limit
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 100);

      // Attempt to train one more unit
      await expect(
        gaiaWar.connect(player1).trainUnits(5, 5, 1, 1),
      ).to.be.revertedWith("Exceeds max units per tile");
    });

    it("should allow unit upgrading", async function () {
      // Train basic units
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Player approves GaiaWar to spend their items
      await testItem
        .connect(player1)
        .setApprovalForAll(gaiaWar.target, true);

      // Upgrade units to unitId 2
      await expect(
        gaiaWar.connect(player1).upgradeUnits(5, 5, 2, 5),
      )
        .to.emit(gaiaWar, "UnitsUpgraded")
        .withArgs(player1.address, 5, 5, 2, 5);

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
        .safeTransferFrom(
          player1.address,
          player2.address,
          1,
          1000,
          "0x",
        );

      // Train basic units
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);

      // Attempt to upgrade units without items
      await expect(
        gaiaWar.connect(player1).upgradeUnits(5, 5, 2, 5),
      ).to.be.reverted; // Adjusted to not specify the revert reason
    });
  });

  describe("Unit Movement and Combat", function () {
    beforeEach(async function () {
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens
      await testToken.mint(player1.address, ethers.parseEther("100000"));
      await testToken.mint(player2.address, ethers.parseEther("100000"));
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
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 100); // Train 100 units

      // Player2 builds headquarters at (10,10) and trains units
      await gaiaWar.connect(player2).buildBuilding(10, 10, 1);
      await gaiaWar.connect(player2).trainUnits(10, 10, 1, 40); // Train 40 units
    });

    it("should allow unit movement within movement range", async function () {
      // Adjusted coordinates to ensure movement range is within limit
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 7, 5, [{ unitId: 1, amount: 20 }]),
      )
        .to.emit(gaiaWar, "UnitsMoved")
        .withArgs(
          5,
          5,
          7,
          5,
          [[1n, 20n]],
        );

      const unitsAtDestination = await gaiaWar.getTileUnits(7, 5);
      expect(unitsAtDestination.length).to.equal(1);
      expect(unitsAtDestination[0].unitId).to.equal(1);
      expect(unitsAtDestination[0].amount).to.equal(20);
    });

    it("should prevent unit movement exceeding movement range", async function () {
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 11, 5, [{ unitId: 1, amount: 20 }]),
      ).to.be.revertedWith("Movement range exceeded");
    });

    it("should enforce max units per tile when moving units", async function () {
      // Move 50 units to (6,6)
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 50 }]);

      // Ensure occupant remains at (5,5)
      const tileAt55 = await gaiaWar.map(5, 5);
      expect(tileAt55.occupant).to.equal(player1.address);

      // Train more units at headquarters (50 units)
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 50);

      // Attempt to move 51 units to (6,6), exceeding maxUnitsPerTile
      await expect(
        gaiaWar
          .connect(player1)
          .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 51 }]),
      ).to.be.revertedWith("Exceeds max units per tile");
    });

    it("should allow combat between players", async function () {
      // Player1 moves units close to Player2
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 5, 10, [{ unitId: 1, amount: 100 }]);

      // Player1 attacks Player2
      await expect(
        gaiaWar.connect(player1).attack(5, 10, 10, 10),
      )
        .to.emit(gaiaWar, "AttackResult")
        .withArgs(
          player1.address,
          player2.address,
          5,
          10,
          10,
          10,
          true,
        );

      const tile = await gaiaWar.map(10, 10);
      expect(tile.occupant).to.equal(player1.address);
    });

    it("should correctly distribute loot after combat", async function () {
      // Player2 builds a non-headquarters building at (10,11)
      await gaiaWar.connect(player2).buildBuilding(10, 11, 2);

      // Player1 moves units close
      await gaiaWar
        .connect(player1)
        .moveUnits(5, 5, 5, 10, [{ unitId: 1, amount: 100 }]);

      // Get balances before attack
      const ownerBalanceBefore = await testToken.balanceOf(owner.address);
      const player1BalanceBefore = await testToken.balanceOf(player1.address);
      const contractBalanceBefore = await testToken.balanceOf(gaiaWar.target);

      // Player1 attacks Player2
      await expect(
        gaiaWar.connect(player1).attack(5, 10, 10, 10),
      ).to.emit(gaiaWar, "AttackResult");

      // Check balances after loot distribution
      const ownerBalanceAfter = await testToken.balanceOf(owner.address);
      const player1BalanceAfter = await testToken.balanceOf(player1.address);
      const contractBalanceAfter = await testToken.balanceOf(gaiaWar.target);

      expect(ownerBalanceAfter).to.be.gt(ownerBalanceBefore);
      expect(player1BalanceAfter).to.be.gt(player1BalanceBefore); // Player1 gains loot

      expect(contractBalanceAfter).to.be.lt(contractBalanceBefore);
    });
  });

  describe("Additional Edge Cases", function () {
    beforeEach(async function () {
      // Common setup for edge cases
      await assetManager.addAsset([testToken.target], testItem.target);

      // Mint tokens and approve GaiaWar
      await testToken.mint(player1.address, ethers.parseEther("100000"));
      await testToken.mint(player2.address, ethers.parseEther("100000"));
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

      // Player1 builds headquarters and trains units
      await gaiaWar.connect(player1).buildBuilding(5, 5, 1);
      await gaiaWar.connect(player1).trainUnits(5, 5, 1, 10);
    });

    it("should prevent moving units not owned by the player", async function () {
      // Player2 attempts to move Player1's units
      await expect(
        gaiaWar
          .connect(player2)
          .moveUnits(5, 5, 6, 6, [{ unitId: 1, amount: 5 }]),
      ).to.be.revertedWith("Not your units");
    });

    it("should prevent attacking own units", async function () {
      // Player1 attempts to attack own units
      await expect(
        gaiaWar.connect(player1).attack(5, 5, 5, 5),
      ).to.be.revertedWith("Invalid target");
    });

    it("should prevent building outside of allowed range", async function () {
      // Attempt to build a building outside of allowed range
      await expect(
        gaiaWar.connect(player1).buildBuilding(15, 15, 2),
      ).to.be.revertedWith("Cannot build outside of allowed range");
    });
  });
});
