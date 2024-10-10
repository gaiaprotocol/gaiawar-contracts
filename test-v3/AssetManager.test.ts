import { expect } from "chai";
import { ethers } from "hardhat";
import { AssetManager, AssetManager__factory } from "../typechain-types";

describe("AssetManager", function () {
  let AssetManagerFactory: AssetManager__factory;
  let assetManager: AssetManager;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    AssetManagerFactory = (await ethers.getContractFactory(
      "AssetManager",
    )) as AssetManager__factory;
    [owner, addr1] = await ethers.getSigners();
    assetManager = (await AssetManagerFactory.deploy()) as AssetManager;
    await assetManager.initialize();
  });

  it("should have currentVersion as 0 upon initialization", async function () {
    expect(await assetManager.currentVersion()).to.equal(0);
  });

  it("should allow the owner to add an asset", async function () {
    const resources = [addr1.address];
    const item = addr1.address;

    await expect(assetManager.addAsset(resources, item))
      .to.emit(assetManager, "AssetAdded")
      .withArgs(1, resources, item);

    expect(await assetManager.currentVersion()).to.equal(1);

    const asset = await assetManager.getAsset(1);
    expect(asset.resources).to.deep.equal(resources);
    expect(asset.item).to.equal(item);
  });

  it("should not allow non-owner to add an asset", async function () {
    const resources = [addr1.address];
    const item = addr1.address;

    await expect(
      assetManager.connect(addr1).addAsset(resources, item),
    ).to.be.revertedWithCustomError(assetManager, "OwnableUnauthorizedAccount");
  });

  it("should return default values for non-existent asset versions", async function () {
    const asset = await assetManager.getAsset(999);
    expect(asset.resources).to.deep.equal([]);
    expect(asset.item).to.equal(ethers.ZeroAddress);
  });
});
