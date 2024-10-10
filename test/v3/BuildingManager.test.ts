import { expect } from "chai";
import { ethers } from "hardhat";
import { BuildingManager, BuildingManager__factory } from "../../typechain-types";

describe("BuildingManager", function () {
  let BuildingManagerFactory: BuildingManager__factory;
  let buildingManager: BuildingManager;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    BuildingManagerFactory = (await ethers.getContractFactory(
      "BuildingManager",
    )) as BuildingManager__factory;
    [owner, addr1] = await ethers.getSigners();
    buildingManager =
      (await BuildingManagerFactory.deploy()) as BuildingManager;
    await buildingManager.initialize();
  });

  it("should allow the owner to add a building", async function () {
    const preUpgradeBuildingId = 0;
    const assetVersion = 1;
    const constructionCosts = [100, 200];
    const isHeadquarters = true;

    await expect(
      buildingManager.addBuilding(
        preUpgradeBuildingId,
        assetVersion,
        constructionCosts,
        isHeadquarters,
      ),
    )
      .to.emit(buildingManager, "BuildingAdded")
      .withArgs(
        1,
        assetVersion,
        preUpgradeBuildingId,
        constructionCosts,
        isHeadquarters,
      );

    const building = await buildingManager.getBuilding(1);
    expect(building.level).to.equal(1);
    expect(building.isHeadquarters).to.equal(true);
  });

  it("should not allow non-owner to add a building", async function () {
    await expect(
      buildingManager.connect(addr1).addBuilding(0, 1, [], false),
    ).to.be.revertedWithCustomError(
      buildingManager,
      "OwnableUnauthorizedAccount",
    );
  });

  it("should correctly manage producible units", async function () {
    // Add a building
    await buildingManager.addBuilding(0, 1, [], false);

    // Add producible units
    await buildingManager.addProducibleUnits(1, [1, 2]);

    expect(await buildingManager.canProduceUnit(1, 1)).to.equal(true);
    expect(await buildingManager.canProduceUnit(1, 2)).to.equal(true);
    expect(await buildingManager.canProduceUnit(1, 3)).to.equal(false);

    // Remove a producible unit
    await buildingManager.removeProducibleUnits(1, [1]);

    expect(await buildingManager.canProduceUnit(1, 1)).to.equal(false);
    expect(await buildingManager.canProduceUnit(1, 2)).to.equal(true);
  });
});
