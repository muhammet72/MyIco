const { ethers } = require("hardhat")
const { moveTime } = require("../utils/moveTime.js")
const { time } = require("@nomicfoundation/hardhat-network-helpers")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer, wallet, foundersFund, foundationFund, partnersFund } = await getNamedAccounts()

  log("----------------------------------------------------")
  log("Ico")

  // log("----------------------------------------------------")
  const arguments1 = ["IcoToken", "ITK", "1000"]
  const icoToken = await deploy("IcoToken", {
    from: deployer,
    args: arguments1,
    log: true,
    //waitConfirmations: network.config.blockConfirmations || 1,
  })
  // const latestBlock = await time.latest()
  // const openingTime = latestBlock + time.duration.weeks(1)
  // const closingTime = openingTime + time.duration.weeks(1)
  const preRate = 500
  const rate = 300
  const cap = ethers.utils.parseEther("100")
  const latestBlock = await ethers.provider.getBlock("latest")
  const openingTime = latestBlock.timestamp + time.duration.weeks(1)
  const closingTime = openingTime + time.duration.weeks(1)
  const releaseTime = closingTime + time.duration.years(1)

  const goal = ethers.utils.parseEther("50")

  log(
    `opening time = ${openingTime}, closing time = ${closingTime}, release Time = ${releaseTime}`,
  )

  // uint256 _preRate,
  //   uint256 _initialRate,
  //   address payable walletAddress,
  //   IERC20 _tokenAddress,
  //   IcoToken _mintableTokenAddress,
  //   uint256 _cap,
  //   uint256 _openingTime,
  //   uint256 _closingTime,
  //   uint256 _goal,
  // address _foundersFund,
  // address _foundationFund,
  // address _partnersFund,
  // uint256 _releaseTime

  const arguments2 = [
    preRate,
    rate,
    wallet,
    icoToken.address,
    icoToken.address,
    cap,
    openingTime,
    closingTime,
    goal,
    foundersFund,
    foundationFund,
    partnersFund,
    releaseTime,
  ]
  const ico = await deploy("Ico", {
    from: deployer,
    args: arguments2,
    log: true,
    //waitConfirmations: network.config.blockConfirmations || 1,
  })
}

module.exports.tags = ["all", "ico"]
