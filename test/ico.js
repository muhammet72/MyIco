const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")
const { assert, expect } = require("chai")
const { moveTime } = require("../utils/moveTime.js")
const { helpers, time } = require("@nomicfoundation/hardhat-network-helpers")

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether")
}

describe("Ico", async () => {
  let icoToken, ico, _escrow, Token2
  let oneEther, cap, investorMinCap, investorMaxCap, goal
  let openingTime, closingTime, PreIcoStage, IcoStage, oneWeek, releaseTime
  let wallet, sender, foundersFund, foundationFund, partnersFund, add1, add2

  beforeEach(async () => {
    ;[deployer, wallet, foundersFund, foundationFund, partnersFund, sender, add1, add2] =
      await ethers.getSigners()

    oneEther = ethers.utils.parseEther("1")
    cap = ethers.utils.parseEther("100")
    investorMinCap = ethers.utils.parseEther("0.01")
    investorMaxCap = ethers.utils.parseEther("50")
    // ___________________________________
    const latestBlock = await ethers.provider.getBlock("latest")
    // we will use second one because of moweTime() and the time increase by a week
    // 1
    // openingTime = latestBlock.timestamp + time.duration.weeks(1)
    // 2
    openingTime = latestBlock.timestamp
    closingTime = openingTime + time.duration.weeks(1)
    releaseTime = closingTime + time.duration.years(1)
    // ___________________________________
    oneWeek = time.duration.weeks(1)
    // convert string to bytes32
    const stringToBytes1 = ethers.utils.formatBytes32String("aa")
    const stringToBytes2 = ethers.utils.formatBytes32String("bb")
    goal = ethers.utils.parseEther("50")
    // ICo stages
    PreIcoStage = 0
    IcoStage = 1

    await deployments.fixture(["all"])
    icoToken = await ethers.getContract("IcoToken", deployer)
    ico = await ethers.getContract("Ico", deployer)

    const Token = await ethers.getContractFactory("IcoToken")
    Token2 = await Token.deploy("Token2", "Token2", "1000000")
    await Token2.deployed()

    // transfer ownership to crowdsale
    await icoToken.transferOwnership(ico.address)

    // // add investors to Whitelist
    await ico.connect(deployer).addWhitelisted(add1.address)
    await ico.connect(deployer).addWhitelisted(add2.address)

    // Track refund escrow
    const RefundEscrowAddress = await ico.escrow()
    _escrow = await ethers.getContractAt("RefundEscrow", RefundEscrowAddress)
    // console.log(`_escrow = ${_escrow}, RefundEscrowAddress = ${RefundEscrowAddress}`)

    // advance time to crowd sale start
    //await network.provider.send("evm_increaseTime", [oneWeek + 1])
    // await time.increaseTo(oneWeek + 1)
    await moveTime(oneWeek + 1)
  })

  describe("set constructor correct", async () => {
    it("should track the preRate ", async () => {
      const _preRate = 500
      expect(await ico.getPreRate()).to.equal(_preRate)
    })
    it("should track the rate ", async () => {
      const _rate = 300
      expect(await ico.rate()).to.equal(_rate)
    })
    it("should track the wallet ", async () => {
      expect(await ico.wallet()).to.equal(wallet.address)
    })
    it("should track the token ", async () => {
      expect(await ico.token()).to.equal(icoToken.address)
    })
    it("should has the correct hard cap ", async () => {
      expect(await ico.getCap()).to.equal(cap)
    })
    it("should has the correct goal ", async () => {
      expect(await ico.getGoal()).to.equal(goal)
    })
  })

  describe("crowsale stages", async () => {
    it("should start PreICO stage ", async () => {
      expect(await ico.stage()).to.equal(PreIcoStage)
    })
    it("should allow only owner to update the stage", async () => {
      await ico.connect(deployer).setCrwodsaleStages(IcoStage)
      expect(await ico.stage()).to.equal(IcoStage)
    })
    it("should revert non-owner  try to update the stage", async () => {
      await expect(ico.connect(sender).setCrwodsaleStages(IcoStage)).to.be.reverted
    })
    it("should set crowdSale stage to preIco and change the rate", async () => {
      const _preRate = 500
      await ico.connect(deployer).setCrwodsaleStages(PreIcoStage)
      expect(await ico.stage()).to.equal(PreIcoStage)
      expect(await ico.rate()).to.equal(_preRate)
    })
    it("should set crowdSale stage to Ico and change the rate", async () => {
      const _rate = 300
      await ico.connect(deployer).setCrwodsaleStages(IcoStage)
      expect(await ico.stage()).to.equal(IcoStage)
      expect(await ico.rate()).to.equal(_rate)
    })
  })

  describe("capped crowdsale", async () => {
    describe("cap stat varibles", () => {
      it("should has the correct hard cap ", async () => {
        expect(await ico.getCap()).to.equal(cap)
      })
      it("should has the correct hard cap ", async () => {
        expect(await ico.investorMinCap()).to.equal(investorMinCap)
      })
      it("should has the correct hard cap ", async () => {
        expect(await ico.investorMaxCap()).to.equal(investorMaxCap)
      })
    })

    describe("buyToken", () => {
      it("should be reverted if contribution less then minimumc cap ", async () => {
        const value = investorMinCap - 10
        await expect(ico.connect(add1).buyTokens(add1.address, { value: value })).to.be.reverted
      })
      it("should be reverted if contribution more then max cap ", async () => {
        const value = investorMaxCap + 10

        await expect(ico.connect(add1).buyTokens(add1.address, { value: value })).to.be.reverted
      })
      it("should be allow", async () => {
        await ico.connect(add2).buyTokens(add2.address, { value: oneEther })
      })
      it("should be allow", async () => {
        await ico.connect(add1).buyTokens(add1.address, { value: oneEther })
        const contribution = await ico.getContributions(add1.address)
        expect(contribution).to.equal(oneEther)
      })
    })
  })

  describe("Timed crowdsale", async () => {
    it("is open", async () => {
      expect(await ico.hasClosed()).to.be.false
      expect(await ico.isOpen()).to.be.true
      const a = await ico.isOpen()
      console.log(a)
    })
    it("is close", async () => {
      // await ethers.provider.send("evm_increaseTime", [closingTime + 5])
      await moveTime(oneWeek + 1)
      expect(await ico.isOpen()).to.be.false
      expect(await ico.hasClosed()).to.be.true
      const a = await ico.hasClosed()
      console.log(a)
    })
  })

  describe("whitelisted crowdsale", function () {
    it("shoul revert if some one try other than owner", async () => {
      await expect(ico.connect(wallet).addWhitelisted(sender.address)).to.be.reverted
    })
    it("is has whitlisted role", async () => {
      expect(await ico._hasRole(add1.address)).to.equal(true)
      expect(await ico._hasRole(add2.address)).to.equal(true)
    })
    it("revert contributions from non-whitelisted investors", async function () {
      const notWhitelisted = sender.address
      await expect(ico.buyTokens(notWhitelisted, { value: oneEther })).to.be.reverted
    })
  })

  describe("Refundable crowdsale", function () {
    beforeEach(async () => {
      await ico.buyTokens(add1.address, { value: oneEther })
    })
    describe("during crowdsale", async () => {
      it("should prevent the investor from claiming refund", async () => {
        await expect(ico.claimRefund(add1.address)).to.be.reverted
        await expect(_escrow.withdraw(add1.address)).to.be.reverted
      })
    })
    describe("when crowdsale the stage PreIco", () => {
      beforeEach(async () => {
        // Crowdsale stage is already PreICO by default
        await ico.buyTokens(add1.address, { value: oneEther })
      })
      it("should forwards funds to the wallet", async () => {
        const hundredEth = ethers.utils.parseEther("100")
        const balance = await ethers.provider.getBalance(wallet.address)
        expect(parseInt(balance)).to.be.greaterThan(parseInt(hundredEth))
      })
    })
    describe("when crowdsale the stage Ico", () => {
      beforeEach(async () => {
        await ico.connect(deployer).setCrwodsaleStages(IcoStage)
        await ico.buyTokens(add1.address, { value: oneEther })
      })
      it("should forwards funds to the wallet", async () => {
        const balance = await ethers.provider.getBalance(_escrow.address)
        expect(parseInt(balance)).to.be.greaterThan(0)
      })
    })
  })

  describe("accepting payment and mint crowdsale", async () => {
    it("should accepy paymet and should buyToken  ", async () => {
      await add1.sendTransaction({ to: ico.address, value: oneEther, gasLimit: 30000000 })
      await ico.connect(add1).buyTokens(add1.address, { value: oneEther })
    })

    it(" mint crowdsale ", async () => {
      const orignalTotalSuply = await icoToken.totalSupply()
      await add1.sendTransaction({ to: ico.address, value: oneEther, gasLimit: 30000000 })
      const newTotalSuply = await icoToken.totalSupply()
      expect(parseInt(newTotalSuply)).to.greaterThan(parseInt(orignalTotalSuply))
    })
  })

  describe("token transfer", async () => {
    it("reverts when trying to transfer from when paused ", async () => {
      await ico.connect(add1).buyTokens(add1.address, { value: oneEther })
      await ico.pauseToken()
      const a = await icoToken.paused()
      console.log(a)
      // await ico.connect(add1).buyTokens(add1.address, { value: oneEther })
      // await icoToken.connect(add1).transfer(add2.address, 100)
      await expect(icoToken.connect(add1).transfer(add2.address, 100)).to.be.reverted
    })
  })

  describe("finalizing the crowdsale", async () => {
    describe("when the goal is not reached", async () => {
      beforeEach(async () => {
        await ico.connect(add1).buyTokens(add1.address, { value: oneEther })
        // closing thime
        await moveTime(oneWeek + 1)
        await ico.connect(deployer).finalize()
      })
      it("allow inverster to refund", async () => {
        await _escrow.connect(add1).withdrawalAllowed(add1.address)
      })
    })
    describe("when the goal is reached", async () => {
      beforeEach(async () => {
        const thirtyEther = ethers.utils.parseEther("30")
        await ico.connect(add1).buyTokens(add1.address, { value: thirtyEther })
        await ico.connect(add2).buyTokens(add2.address, { value: thirtyEther })

        // closing hime
        await moveTime(oneWeek + 1)
        await ico.finalize({ gasLimit: 1200000 })
      })

      it("the goal reached", async () => {
        // tracks goal reached
        expect(await ico.goalReached()).to.be.true

        // // Enables token transfers
        await ico.connect(deployer).withdrawTokens(add1.address)
        await icoToken.connect(add1).transfer(add2.address, 100)

        // total suply
        const totalSupply = (await icoToken.totalSupply()).toString()

        // Founders
        const foundersTimelockAddress = await ico.foundersTimelock()
        let foundersTimelockBalance = await icoToken.balanceOf(foundersTimelockAddress)
        foundersTimelockBalance = foundersTimelockBalance.toString()
        foundersTimelockBalance = foundersTimelockBalance / 10 ** 18

        let foundersAmount = totalSupply / 10
        foundersAmount = foundersAmount.toString()
        foundersAmount = foundersAmount / 10 ** 18

        assert.equal(foundersTimelockBalance.toString(), foundersAmount.toString())

        // Foundation
        const foundationTimelockAddress = await ico.foundationTimelock()
        let foundationTimelockBalance = await icoToken.balanceOf(foundationTimelockAddress)
        foundationTimelockBalance = foundationTimelockBalance.toString()
        foundationTimelockBalance = foundationTimelockBalance / 10 ** 18

        let foundationAmount = totalSupply / 10
        foundationAmount = foundationAmount.toString()
        foundationAmount = foundationAmount / 10 ** 18

        assert.equal(foundationTimelockBalance.toString(), foundationAmount.toString())

        // Partners
        const partnersTimelockAddress = await ico.partnersTimelock()
        let partnersTimelockBalance = await icoToken.balanceOf(partnersTimelockAddress)
        partnersTimelockBalance = partnersTimelockBalance.toString()
        partnersTimelockBalance = partnersTimelockBalance / 10 ** 18

        let partnersAmount = totalSupply / 10
        partnersAmount = partnersAmount.toString()
        partnersAmount = partnersAmount / 10 ** 18

        assert.equal(partnersTimelockBalance.toString(), partnersAmount.toString())
        await ethers.getContractAt("TokenTimelock", partnersTimelockAddress)
        // Can't withdraw from timelocks
        const foundersTimelock = await ethers.getContractAt(
          "TokenTimelock",
          foundersTimelockAddress,
        )
        await expect(foundersTimelock.release()).to.be.reverted

        const foundationTimelock = await ethers.getContractAt(
          "TokenTimelock",
          foundationTimelockAddress,
        )
        await expect(foundationTimelock.release()).to.be.reverted

        const partnersTimelock = await ethers.getContractAt(
          "TokenTimelock",
          partnersTimelockAddress,
        )
        await expect(partnersTimelock.release()).to.be.reverted

        // Can withdraw from timelocks
        await moveTime(releaseTime + 1)

        await foundersTimelock.release()
        await foundationTimelock.release()
        await partnersTimelock.release()

        // Funds now have balances

        // Founders
        let foundersBalance = await icoToken.balanceOf(foundersFund.address)
        foundersBalance = foundersBalance.toString()
        foundersBalance = foundersBalance / 10 ** 18

        assert.equal(foundersBalance.toString(), foundersAmount.toString())

        // Foundation
        let foundationBalance = await icoToken.balanceOf(foundationFund.address)
        foundationBalance = foundationBalance.toString()
        foundationBalance = foundationBalance / 10 ** 18

        assert.equal(foundationBalance.toString(), foundationAmount.toString())

        // Partners
        let partnersBalance = await icoToken.balanceOf(partnersFund.address)
        partnersBalance = partnersBalance.toString()
        partnersBalance = partnersBalance / 10 ** 18

        assert.equal(partnersBalance.toString(), partnersAmount.toString())

        // transfer owner ship
        expect(await icoToken.owner()).to.equal(wallet.address)

        // prevent investor claiming refund
        await expect(ico.claimRefund(add1.address)).to.be.reverted
        await expect(_escrow.withdraw(add2.address)).to.be.reverted
      })
    })
  })

  describe("token distribution", async () => {
    beforeEach(async () => {
      const tokenSalePercentage = await ico.tokenSalePercentage()
      const foundersPercentage = await ico.foundersPercentage()
      const foundationPercentage = await ico.foundationPercentage()
      const partnersPercentage = await ico.partnersPercentage()
      const total =
        tokenSalePercentage.toNumber() +
        foundersPercentage.toNumber() +
        foundationPercentage.toNumber() +
        partnersPercentage.toNumber()
      expect(total).to.equal(100)
    })
    it("get token distrubution correctly", async () => {
      expect(await ico.tokenSalePercentage()).to.equal(70)
      expect(await ico.foundersPercentage()).to.equal(10)
      expect(await ico.foundationPercentage()).to.equal(10)
      expect(await ico.partnersPercentage()).to.equal(10)
    })
    it("Token reserve funds", async () => {
      expect(await ico.foundersFund()).to.equal(foundersFund.address)
      expect(await ico.foundationFund()).to.equal(foundationFund.address)
      expect(await ico.partnersFund()).to.equal(partnersFund.address)
    })
  })

  describe("set new Ico", () => {
    beforeEach(async () => {
      const preRate = 800
      const rate = 400
      const cap = ethers.utils.parseEther("200")
      const latestBlock = await ethers.provider.getBlock("latest")
      const openingTime = latestBlock.timestamp + time.duration.weeks(3)
      const closingTime = openingTime + time.duration.weeks(1)
      const releaseTime = closingTime + time.duration.years(1)
      const goal = ethers.utils.parseEther("70")

      await moveTime(oneWeek + 1)
      await ico.finalize({ gasLimit: 12000000 })
      expect(await ico.finalized()).to.be.true
      await ico.setNewIco(
        preRate,
        rate,
        deployer.address,
        Token2.address,
        Token2.address,
        cap,
        openingTime,
        closingTime,
        goal,
        sender.address,
        add1.address,
        add2.address,
        releaseTime,
      )
      // const b = await ico.icosAddress([1])
      // const a = await ico.getAllIco()
      // expect(await ico.icosAddress([1])).to.equal(Token2.address)
      // console.log(`from contract = ${b}, from test ${Token2.address}`)
      // console.log(a)
    })
    it("set all variables correctly", async () => {
      const preRate = 800
      const rate = 400
      const cap = ethers.utils.parseEther("200")
      const goal = ethers.utils.parseEther("70")
      expect(await ico.getPreRate()).to.equal(preRate)
      expect(await ico.rate()).to.equal(rate)
      expect(await ico.wallet()).to.equal(deployer.address)
      expect(await ico.token()).to.equal(Token2.address)
      expect(await ico.getMintableToken()).to.equal(Token2.address)
      expect(await ico.getCap()).to.equal(cap)
      expect(await ico.getGoal()).to.equal(goal)
    })
    it("get icos Address ", async () => {
      expect(await ico.icosAddress([0])).to.equal(icoToken.address)
      expect(await ico.icosAddress([1])).to.equal(Token2.address)
    })
  })
})
