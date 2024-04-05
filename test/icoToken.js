const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { assert, expect } = require("chai")

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether")
}

describe("IcoToken", async () => {
  let icoToken, add1, add2
  let accounts = []
  let name, symbol, totalSupply
  beforeEach(async () => {
    // deployer = (await getNamedAccounts()).deployer
    ;[deployer, add1, add2] = await ethers.getSigners()

    await deployments.fixture(["all"])
    icoToken = await ethers.getContract("IcoToken", deployer)
    name = "IcoToken"
    symbol = "ITK"
    totalSupply = tokens(1000)
  })
  describe("set state variables corecet", () => {
    it("should set owner correct", async () => {
      expect(await icoToken.owner()).to.equal(deployer.address)
    })

    it("should set name correct", async () => {
      expect(await icoToken.name()).to.equal(name)
    })

    it("should set symbol correct", async () => {
      expect(await icoToken.symbol()).to.equal(symbol)
    })

    it("has 18 decimals", async function () {
      expect(await icoToken.decimals()).to.equal(18)
    })

    it("should set totalSupply correct", async () => {
      expect(await icoToken.totalSupply()).to.equal(totalSupply)
    })
  })

  describe("should only owner can mint", () => {
    it("should revert not owner try to mint", async () => {
      const amount = tokens(100)
      await expect(icoToken.connect(add1).mint(add2.address, amount)).to.be.revertedWith(
        "OwnableUnauthorizedAccount",
      )
    })
    it("should mint ", async () => {
      const amount = tokens(100)
      await icoToken.connect(deployer).mint(add1.address, amount)
      const newTotalSupply = tokens(1000 + 100)
      expect(await icoToken.totalSupply()).to.equal(newTotalSupply)
    })
  })
})
