import { expect } from "chai";
import { ethers } from "hardhat";
import {
  AssetRegistry,
  AssetRegistry__factory,
  BuildingRegistry,
  BuildingRegistry__factory,
  ConstructionManager,
  ConstructionManager__factory,
  MapStorage,
  MapStorage__factory,
  TestERC20,
  TestERC20__factory,
} from "../typechain-types";

describe("ConstructionManager", function () {
  let constructionManager: ConstructionManager;
  let assetRegistry: AssetRegistry;
  let buildingRegistry: BuildingRegistry;
  let mapStorage: MapStorage;
  let testToken: TestERC20;
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
    await testToken.waitForDeployment();

    // Deploy and initialize AssetRegistry
    const AssetRegistryFactory = await ethers.getContractFactory(
      "AssetRegistry",
    ) as AssetRegistry__factory;
    assetRegistry = await AssetRegistryFactory.deploy();
    await assetRegistry.initialize();

    // Deploy and initialize BuildingRegistry
    const BuildingRegistryFactory = await ethers.getContractFactory(
      "BuildingRegistry",
    ) as BuildingRegistry__factory;
    buildingRegistry = await BuildingRegistryFactory.deploy();
    await buildingRegistry.initialize();

    // Deploy and initialize MapStorage
    const MapStorageFactory = await ethers.getContractFactory(
      "MapStorage",
    ) as MapStorage__factory;
    mapStorage = await MapStorageFactory.deploy();
    await mapStorage.initialize(20, 20, 100);

    // Deploy and initialize ConstructionManager
    const ConstructionManagerFactory = await ethers.getContractFactory(
      "ConstructionManager",
    ) as ConstructionManager__factory;
    constructionManager = await ConstructionManagerFactory.deploy();
    await constructionManager.initialize(
      assetRegistry.target,
      buildingRegistry.target,
      mapStorage.target,
    );

    // Add asset to AssetRegistry
    await assetRegistry.addAsset([testToken.target], ethers.ZeroAddress);

    // Add buildings to BuildingRegistry
    await buildingRegistry.addBuilding(0, 1, [ethers.parseEther("500")], true); // Headquarters
    await buildingRegistry.addBuilding(0, 1, [ethers.parseEther("300")], false); // Regular building

    // Mint tokens to players and approve ConstructionManager
    await testToken.mint(player1.address, ethers.parseEther("10000"));
    await testToken.mint(player2.address, ethers.parseEther("10000"));
    await testToken.connect(player1).approve(
      constructionManager.target,
      ethers.MaxUint256,
    );
    await testToken.connect(player2).approve(
      constructionManager.target,
      ethers.MaxUint256,
    );

    // Add ConstructionManager to MapStorage whitelist
    await mapStorage.addToWhitelist(constructionManager.target);
  });

  describe("Initialization", function () {
    it("should initialize with correct values", async function () {
      expect(await constructionManager.assetRegistry()).to.equal(
        assetRegistry.target,
      );
      expect(await constructionManager.buildingRegistry()).to.equal(
        buildingRegistry.target,
      );
      expect(await constructionManager.mapStorage()).to.equal(
        mapStorage.target,
      );
    });
  });

  describe("Building Construction", function () {
    it("should allow player to construct a headquarters", async function () {
      await expect(
        constructionManager.connect(player1).constructBuilding(5, 5, 1),
      )
        .to.emit(constructionManager, "BuildingConstructed")
        .withArgs(player1.address, 5, 5, 1);

      expect(await mapStorage.getTileOccupant(5, 5)).to.equal(player1.address);
      expect(await mapStorage.getTileBuildingId(5, 5)).to.equal(1);
    });

    it("should allow player to construct a regular building near headquarters", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1); // Construct HQ
      await expect(
        constructionManager.connect(player1).constructBuilding(6, 6, 2),
      )
        .to.emit(constructionManager, "BuildingConstructed")
        .withArgs(player1.address, 6, 6, 2);

      expect(await mapStorage.getTileOccupant(6, 6)).to.equal(player1.address);
      expect(await mapStorage.getTileBuildingId(6, 6)).to.equal(2);
    });

    it("should prevent constructing on an occupied tile", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);
      await expect(
        constructionManager.connect(player2).constructBuilding(5, 5, 1),
      )
        .to.be.revertedWith("Tile occupied by another player");
    });

    it("should prevent constructing near enemy buildings", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);
      await expect(
        constructionManager.connect(player2).constructBuilding(6, 6, 1),
      )
        .to.be.revertedWith("Cannot build near enemy building");
    });

    it("should prevent constructing regular building outside of headquarters range", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1); // Construct HQ
      await expect(
        constructionManager.connect(player1).constructBuilding(15, 15, 2),
      )
        .to.be.revertedWith("Cannot build outside of allowed range");
    });
  });

  describe("Building Upgrade", function () {
    beforeEach(async function () {
      await buildingRegistry.addBuilding(
        1,
        1,
        [ethers.parseEther("1000")],
        true,
      ); // Upgraded HQ
    });

    it("should allow upgrading a building", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);
      await expect(
        constructionManager.connect(player1).upgradeBuilding(5, 5, 3),
      )
        .to.emit(constructionManager, "BuildingConstructed")
        .withArgs(player1.address, 5, 5, 3);

      expect(await mapStorage.getTileBuildingId(5, 5)).to.equal(3);
    });

    it("should prevent upgrading a non-existent building", async function () {
      await expect(
        constructionManager.connect(player1).upgradeBuilding(5, 5, 3),
      )
        .to.be.revertedWith("Not your building");
    });

    it("should prevent upgrading to an invalid building type", async function () {
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);
      await expect(
        constructionManager.connect(player1).upgradeBuilding(5, 5, 2),
      )
        .to.be.revertedWith("Invalid upgrade");
    });
  });

  describe("Resource Management", function () {
    it("should deduct resources when constructing a building", async function () {
      const initialBalance = await testToken.balanceOf(player1.address);
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);
      const finalBalance = await testToken.balanceOf(player1.address);
      expect(initialBalance - finalBalance).to.equal(
        ethers.parseEther("500"),
      );
    });

    it("should deduct resources when upgrading a building", async function () {
      await buildingRegistry.addBuilding(
        1,
        1,
        [ethers.parseEther("1000")],
        true,
      ); // Upgraded HQ
      await constructionManager.connect(player1).constructBuilding(5, 5, 1);

      const initialBalance = await testToken.balanceOf(player1.address);
      await constructionManager.connect(player1).upgradeBuilding(5, 5, 3);
      const finalBalance = await testToken.balanceOf(player1.address);
      expect(initialBalance - finalBalance).to.equal(
        ethers.parseEther("1000"),
      );
    });

    it("should prevent construction when player lacks resources", async function () {
      await testToken.connect(player1).transfer(
        player2.address,
        await testToken.balanceOf(player1.address),
      );
      await expect(
        constructionManager.connect(player1).constructBuilding(5, 5, 1),
      )
        .to.be.reverted; // The exact error message may vary depending on the ERC20 implementation
    });
  });

  describe("Admin Functions", function () {
    it("should allow owner to set new AssetRegistry", async function () {
      const newAssetRegistry = await (new AssetRegistry__factory(owner))
        .deploy();
      await expect(
        constructionManager.setAssetRegistry(newAssetRegistry.target),
      )
        .to.emit(constructionManager, "AssetRegistrySet")
        .withArgs(newAssetRegistry.target);
      expect(await constructionManager.assetRegistry()).to.equal(
        newAssetRegistry.target,
      );
    });

    it("should allow owner to set new BuildingRegistry", async function () {
      const newBuildingRegistry = await (new BuildingRegistry__factory(owner))
        .deploy();
      await expect(
        constructionManager.setBuildingRegistry(newBuildingRegistry.target),
      )
        .to.emit(constructionManager, "BuildingRegistrySet")
        .withArgs(newBuildingRegistry.target);
      expect(await constructionManager.buildingRegistry()).to.equal(
        newBuildingRegistry.target,
      );
    });

    it("should allow owner to set new MapStorage", async function () {
      const newMapStorage = await (new MapStorage__factory(owner)).deploy();
      await expect(constructionManager.setMapStorage(newMapStorage.target))
        .to.emit(constructionManager, "MapStorageSet")
        .withArgs(newMapStorage.target);
      expect(await constructionManager.mapStorage()).to.equal(
        newMapStorage.target,
      );
    });

    it("should prevent non-owner from setting new registries", async function () {
      const newAssetRegistry = await (new AssetRegistry__factory(owner))
        .deploy();
      await expect(
        constructionManager.connect(player1).setAssetRegistry(
          newAssetRegistry.target,
        ),
      )
        .to.be.revertedWithCustomError(
          constructionManager,
          "OwnableUnauthorizedAccount",
        );
    });
  });
});
