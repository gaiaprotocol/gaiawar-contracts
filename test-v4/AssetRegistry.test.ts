import { expect } from "chai";
import { ethers } from "hardhat";
import { AssetRegistry, AssetRegistry__factory } from "../typechain-types";

describe("AssetRegistry", function () {
  let AssetRegistryFactory: AssetRegistry__factory;
  let assetRegistry: AssetRegistry;
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    AssetRegistryFactory = (await ethers.getContractFactory(
      "AssetRegistry",
    )) as AssetRegistry__factory;
    [owner, addr1, addr2] = await ethers.getSigners();
    assetRegistry = (await AssetRegistryFactory.deploy()) as AssetRegistry;
    await assetRegistry.initialize();
  });

  describe("Initialization", function () {
    it("should have currentVersion as 0 upon initialization", async function () {
      expect(await assetRegistry.currentVersion()).to.equal(0);
    });

    it("should set the deployer as the owner", async function () {
      expect(await assetRegistry.owner()).to.equal(owner.address);
    });
  });

  describe("Asset Management", function () {
    it("should allow the owner to add an asset", async function () {
      const resources = [addr1.address, addr2.address];
      const item = addr1.address;

      await expect(assetRegistry.addAsset(resources, item))
        .to.emit(assetRegistry, "AssetAdded")
        .withArgs(1, resources, item);

      expect(await assetRegistry.currentVersion()).to.equal(1);

      const asset = await assetRegistry.getAsset(1);
      expect(asset.resources).to.deep.equal(resources);
      expect(asset.item).to.equal(item);
    });

    it("should not allow non-owner to add an asset", async function () {
      const resources = [addr1.address];
      const item = addr1.address;

      await expect(
        assetRegistry.connect(addr1).addAsset(resources, item),
      ).to.be.revertedWithCustomError(
        assetRegistry,
        "OwnableUnauthorizedAccount",
      );
    });

    it("should return default values for non-existent asset versions", async function () {
      const asset = await assetRegistry.getAsset(999);
      expect(asset.resources).to.deep.equal([]);
      expect(asset.item).to.equal(ethers.ZeroAddress);
    });

    it("should allow adding multiple assets and retrieve them correctly", async function () {
      const assets = [
        { resources: [addr1.address], item: addr2.address },
        { resources: [addr2.address, owner.address], item: addr1.address },
        { resources: [], item: owner.address },
      ];

      for (let i = 0; i < assets.length; i++) {
        await assetRegistry.addAsset(assets[i].resources, assets[i].item);
        expect(await assetRegistry.currentVersion()).to.equal(i + 1);
      }

      for (let i = 0; i < assets.length; i++) {
        const asset = await assetRegistry.getAsset(i + 1);
        expect(asset.resources).to.deep.equal(assets[i].resources);
        expect(asset.item).to.equal(assets[i].item);
      }
    });
  });

  describe("Ownership", function () {
    it("should allow the owner to transfer ownership", async function () {
      await expect(assetRegistry.transferOwnership(addr1.address))
        .to.emit(assetRegistry, "OwnershipTransferred")
        .withArgs(owner.address, addr1.address);

      expect(await assetRegistry.owner()).to.equal(addr1.address);
    });

    it("should not allow non-owner to transfer ownership", async function () {
      await expect(
        assetRegistry.connect(addr1).transferOwnership(addr2.address),
      ).to.be.revertedWithCustomError(
        assetRegistry,
        "OwnableUnauthorizedAccount",
      );
    });
  });

  describe("Edge Cases", function () {
    it("should handle adding an asset with empty resources", async function () {
      const resources: string[] = [];
      const item = addr1.address;

      await expect(assetRegistry.addAsset(resources, item))
        .to.emit(assetRegistry, "AssetAdded")
        .withArgs(1, resources, item);

      const asset = await assetRegistry.getAsset(1);
      expect(asset.resources).to.deep.equal([]);
      expect(asset.item).to.equal(item);
    });

    it("should handle adding an asset with zero address as item", async function () {
      const resources = [addr1.address];
      const item = ethers.ZeroAddress;

      await expect(assetRegistry.addAsset(resources, item))
        .to.emit(assetRegistry, "AssetAdded")
        .withArgs(1, resources, item);

      const asset = await assetRegistry.getAsset(1);
      expect(asset.resources).to.deep.equal(resources);
      expect(asset.item).to.equal(item);
    });
  });
});
