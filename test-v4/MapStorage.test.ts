import { expect } from "chai";
import { ethers } from "hardhat";
import { MapStorage, MapStorage__factory } from "../typechain-types";

describe("MapStorage", function () {
  let MapStorageFactory: MapStorage__factory;
  let mapStorage: MapStorage;
  let owner: any;
  let addr1: any;
  let addr2: any;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    MapStorageFactory =
      (await ethers.getContractFactory("MapStorage")) as MapStorage__factory;
    mapStorage = await MapStorageFactory.deploy();
    await mapStorage.initialize(20, 20, 100);
  });

  describe("Initialization", function () {
    it("should initialize with correct values", async function () {
      expect(await mapStorage.mapRows()).to.equal(20);
      expect(await mapStorage.mapCols()).to.equal(20);
      expect(await mapStorage.maxUnitsPerTile()).to.equal(100);
    });

    it("should set the deployer as the owner", async function () {
      expect(await mapStorage.owner()).to.equal(owner.address);
    });
  });

  describe("Map Size Management", function () {
    it("should allow owner to update map size", async function () {
      await expect(mapStorage.setMapSize(30, 30))
        .to.emit(mapStorage, "MapSizeUpdated")
        .withArgs(30, 30);

      expect(await mapStorage.mapRows()).to.equal(30);
      expect(await mapStorage.mapCols()).to.equal(30);
    });

    it("should not allow non-owner to update map size", async function () {
      await expect(mapStorage.connect(addr1).setMapSize(30, 30))
        .to.be.revertedWithCustomError(
          mapStorage,
          "OwnableUnauthorizedAccount",
        );
    });
  });

  describe("Max Units Per Tile Management", function () {
    it("should allow owner to update max units per tile", async function () {
      await expect(mapStorage.setMaxUnitsPerTile(150))
        .to.emit(mapStorage, "MaxUnitsPerTileUpdated")
        .withArgs(150);

      expect(await mapStorage.maxUnitsPerTile()).to.equal(150);
    });

    it("should not allow non-owner to update max units per tile", async function () {
      await expect(mapStorage.connect(addr1).setMaxUnitsPerTile(150))
        .to.be.revertedWithCustomError(
          mapStorage,
          "OwnableUnauthorizedAccount",
        );
    });
  });

  describe("Whitelist Management", function () {
    it("should allow owner to add address to whitelist", async function () {
      await expect(mapStorage.addToWhitelist(addr1.address))
        .to.emit(mapStorage, "WhitelistAdded")
        .withArgs(addr1.address);

      expect(await mapStorage.isWhitelisted(addr1.address)).to.be.true;
    });

    it("should allow owner to remove address from whitelist", async function () {
      await mapStorage.addToWhitelist(addr1.address);
      await expect(mapStorage.removeFromWhitelist(addr1.address))
        .to.emit(mapStorage, "WhitelistRemoved")
        .withArgs(addr1.address);

      expect(await mapStorage.isWhitelisted(addr1.address)).to.be.false;
    });

    it("should not allow non-owner to manage whitelist", async function () {
      await expect(mapStorage.connect(addr1).addToWhitelist(addr2.address))
        .to.be.revertedWithCustomError(
          mapStorage,
          "OwnableUnauthorizedAccount",
        );

      await expect(mapStorage.connect(addr1).removeFromWhitelist(addr2.address))
        .to.be.revertedWithCustomError(
          mapStorage,
          "OwnableUnauthorizedAccount",
        );
    });

    it("should not allow adding already whitelisted address", async function () {
      await mapStorage.addToWhitelist(addr1.address);
      await expect(mapStorage.addToWhitelist(addr1.address))
        .to.be.revertedWith("Address is already whitelisted");
    });

    it("should not allow removing non-whitelisted address", async function () {
      await expect(mapStorage.removeFromWhitelist(addr1.address))
        .to.be.revertedWith("Address is not whitelisted");
    });
  });

  describe("Tile Data Management", function () {
    beforeEach(async function () {
      await mapStorage.addToWhitelist(owner.address);
    });

    it("should allow whitelisted address to update tile occupant", async function () {
      await expect(mapStorage.updateTileOccupant(5, 5, addr1.address))
        .to.emit(mapStorage, "TileOccupantUpdated")
        .withArgs(5, 5, addr1.address);

      expect(await mapStorage.getTileOccupant(5, 5)).to.equal(addr1.address);
    });

    it("should allow whitelisted address to update tile building", async function () {
      await expect(mapStorage.updateTileBuildingId(5, 5, 1))
        .to.emit(mapStorage, "TileBuildingUpdated")
        .withArgs(5, 5, 1);

      expect(await mapStorage.getTileBuildingId(5, 5)).to.equal(1);
    });

    it("should allow whitelisted address to update tile units", async function () {
      await expect(
        mapStorage.updateTileUnits(5, 5, [{ unitId: 1, amount: 10 }, {
          unitId: 2,
          amount: 20,
        }]),
      )
        .to.emit(mapStorage, "TileUnitsUpdated")
        .withArgs(5, 5, [[1n, 10n], [2n, 20n]]);

      const updatedUnits = await mapStorage.getTileUnits(5, 5);
      expect(updatedUnits.length).to.equal(2);
      expect(updatedUnits[0].unitId).to.equal(1);
      expect(updatedUnits[0].amount).to.equal(10);
      expect(updatedUnits[1].unitId).to.equal(2);
      expect(updatedUnits[1].amount).to.equal(20);
    });

    it("should not allow non-whitelisted address to update tile data", async function () {
      await expect(
        mapStorage.connect(addr1).updateTileOccupant(5, 5, addr2.address),
      )
        .to.be.revertedWith("Not whitelisted");

      await expect(mapStorage.connect(addr1).updateTileBuildingId(5, 5, 1))
        .to.be.revertedWith("Not whitelisted");

      await expect(
        mapStorage.connect(addr1).updateTileUnits(5, 5, [{
          unitId: 1,
          amount: 10,
        }]),
      )
        .to.be.revertedWith("Not whitelisted");
    });

    it("should not allow updating tile with invalid coordinates", async function () {
      await expect(mapStorage.updateTileOccupant(100, 100, addr1.address))
        .to.be.revertedWith("Invalid coordinates");

      await expect(mapStorage.updateTileBuildingId(100, 100, 1))
        .to.be.revertedWith("Invalid coordinates");

      await expect(
        mapStorage.updateTileUnits(100, 100, [{ unitId: 1, amount: 10 }]),
      )
        .to.be.revertedWith("Invalid coordinates");
    });

    it("should not allow updating tile with too many units", async function () {
      const tooManyUnits = Array(101).fill({ unitId: 1, amount: 1 });
      await expect(mapStorage.updateTileUnits(5, 5, tooManyUnits))
        .to.be.revertedWith("Too many units");
    });
  });

  describe("Tile Data Retrieval", function () {
    beforeEach(async function () {
      await mapStorage.addToWhitelist(owner.address);
      await mapStorage.updateTileOccupant(5, 5, addr1.address);
      await mapStorage.updateTileBuildingId(5, 5, 1);
      await mapStorage.updateTileUnits(5, 5, [{ unitId: 1, amount: 10 }, {
        unitId: 2,
        amount: 20,
      }]);
    });

    it("should correctly retrieve tile occupant", async function () {
      expect(await mapStorage.getTileOccupant(5, 5)).to.equal(addr1.address);
    });

    it("should correctly retrieve tile building ID", async function () {
      expect(await mapStorage.getTileBuildingId(5, 5)).to.equal(1);
    });

    it("should correctly retrieve tile units", async function () {
      const units = await mapStorage.getTileUnits(5, 5);
      expect(units.length).to.equal(2);
      expect(units[0].unitId).to.equal(1);
      expect(units[0].amount).to.equal(10);
      expect(units[1].unitId).to.equal(2);
      expect(units[1].amount).to.equal(20);
    });

    it("should return default values for non-existent tiles", async function () {
      expect(await mapStorage.getTileOccupant(10, 10)).to.equal(
        ethers.ZeroAddress,
      );
      expect(await mapStorage.getTileBuildingId(10, 10)).to.equal(0);
      expect((await mapStorage.getTileUnits(10, 10)).length).to.equal(0);
    });

    it("should not allow retrieval with invalid coordinates", async function () {
      await expect(mapStorage.getTileOccupant(100, 100)).to.be.revertedWith(
        "Invalid coordinates",
      );
      await expect(mapStorage.getTileBuildingId(100, 100)).to.be.revertedWith(
        "Invalid coordinates",
      );
      await expect(mapStorage.getTileUnits(100, 100)).to.be.revertedWith(
        "Invalid coordinates",
      );
    });
  });
});
