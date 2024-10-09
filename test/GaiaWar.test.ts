import { expect } from "chai";
import { ethers } from "hardhat";
import {
  AssetManager,
  AssetManager__factory,
  BuildingManager,
  BuildingManager__factory,
  GaiaWar,
  GaiaWar__factory,
  TestERC20,
  TestERC20__factory,
  UnitManager,
  UnitManager__factory,
} from "../typechain-types";

describe("GaiaWar", function () {
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
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy TestERC20
    TestERC20Factory = await ethers.getContractFactory(
      "TestERC20",
    ) as TestERC20__factory;
    testToken = await TestERC20Factory.deploy("Test Token", "TST") as TestERC20;
    await testToken.waitForDeployment();

    AssetManagerFactory = (await ethers.getContractFactory(
      "AssetManager",
    )) as AssetManager__factory;
    assetManager = (await AssetManagerFactory.deploy()) as AssetManager;
    await assetManager.initialize();

    BuildingManagerFactory = (await ethers.getContractFactory(
      "BuildingManager",
    )) as BuildingManager__factory;
    buildingManager =
      (await BuildingManagerFactory.deploy()) as BuildingManager;
    await buildingManager.initialize();

    UnitManagerFactory =
      (await ethers.getContractFactory("UnitManager")) as UnitManager__factory;
    unitManager = (await UnitManagerFactory.deploy()) as UnitManager;
    await unitManager.initialize();

    GaiaWarFactory =
      (await ethers.getContractFactory("GaiaWar")) as GaiaWar__factory;
    gaiaWar = (await GaiaWarFactory.deploy()) as GaiaWar;
    await gaiaWar.initialize(
      assetManager.target,
      buildingManager.target,
      unitManager.target,
      10, // mapRows
      10, // mapCols
      100, // maxUnitsPerTile
      5, // maxUnitMovementRange
      10, // ownerSharePercentage
    );
  });

  it("should initialize the contract correctly", async function () {
    expect(await gaiaWar.assetManager()).to.equal(assetManager.target);
    expect(await gaiaWar.buildingManager()).to.equal(buildingManager.target);
    expect(await gaiaWar.unitManager()).to.equal(unitManager.target);
    expect(await gaiaWar.mapRows()).to.equal(10);
    expect(await gaiaWar.mapCols()).to.equal(10);
    expect(await gaiaWar.maxUnitsPerTile()).to.equal(100);
    expect(await gaiaWar.maxUnitMovementRange()).to.equal(5);
    expect(await gaiaWar.ownerSharePercentage()).to.equal(10);
  });

  it("should allow the owner to change map settings", async function () {
    await gaiaWar.setMapSize(20, 20);
    expect(await gaiaWar.mapRows()).to.equal(20);
    expect(await gaiaWar.mapCols()).to.equal(20);

    await gaiaWar.setMaxUnitsPerTile(200);
    expect(await gaiaWar.maxUnitsPerTile()).to.equal(200);

    await gaiaWar.setMaxUnitMovementRange(10);
    expect(await gaiaWar.maxUnitMovementRange()).to.equal(10);

    await gaiaWar.setOwnerSharePercentage(15);
    expect(await gaiaWar.ownerSharePercentage()).to.equal(15);
  });

  it("should not allow non-owner to change map settings", async function () {
    await expect(
      gaiaWar.connect(addr1).setMapSize(20, 20),
    ).to.be.revertedWithCustomError(gaiaWar, "OwnableUnauthorizedAccount");
  });

  describe("Unit movement and attack tests", function () {
    beforeEach(async function () {
      // Setup assets and units
      await assetManager.addAsset([testToken.target], ethers.ZeroAddress);
      await unitManager.addUnit(100, 50, 1, 1, [100], 0, 0);
      await buildingManager.addBuilding(0, 1, [100], true);
      await buildingManager.addProducibleUnits(1, [1]);

      // Mint some tokens for addr1 and addr2
      await testToken.mint(addr1.address, ethers.parseEther("1000"));
      await testToken.mint(addr2.address, ethers.parseEther("1000"));

      // Approve GaiaWar contract to spend tokens
      await testToken.connect(addr1).approve(
        gaiaWar.target,
        ethers.MaxUint256,
      );
      await testToken.connect(addr2).approve(
        gaiaWar.target,
        ethers.MaxUint256,
      );

      // addr1 builds headquarters
      await gaiaWar.connect(addr1).buildBuilding(1, 1, 1);
      // addr1 trains units
      await gaiaWar.connect(addr1).trainUnits(1, 1, 1, 10);
    });

    it("should allow addr1 to move units", async function () {
      await expect(
        gaiaWar.connect(addr1).moveUnits(1, 1, 2, 2, [{
          unitId: 1,
          amount: 5,
        }]),
      )
        .to.emit(gaiaWar, "UnitsMoved")
        .withArgs(1, 1, 2, 2, [[1n, 5n]]);

      // Check tile state after movement
      const fromTileUnits = await gaiaWar.getTileUnits(1, 1);
      expect(fromTileUnits.length).to.equal(1);
      expect(fromTileUnits[0].amount).to.equal(5);

      const toTileUnits = await gaiaWar.getTileUnits(2, 2);
      expect(toTileUnits.length).to.equal(1);
      expect(toTileUnits[0].amount).to.equal(5);
    });

    it("should allow addr1 to attack addr2", async function () {
      // addr2 builds headquarters and trains units
      await gaiaWar.connect(addr2).buildBuilding(3, 3, 1);
      await gaiaWar.connect(addr2).trainUnits(3, 3, 1, 5);

      // addr1 moves units to attack position
      await gaiaWar.connect(addr1).moveUnits(1, 1, 2, 2, [{
        unitId: 1,
        amount: 10,
      }]);

      // Execute attack
      await expect(
        gaiaWar.connect(addr1).attack(2, 2, 3, 3),
      ).to.emit(gaiaWar, "AttackResult");

      // Verify attack results
      const tile = await gaiaWar.map(3, 3);
      expect(tile.occupant).to.equal(addr1.address);
    });
  });
});
