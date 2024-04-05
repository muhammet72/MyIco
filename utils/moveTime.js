const { network } = require("hardhat")

async function moveTime(amount) {
  // console.log("moveing Time......")
  await network.provider.send("evm_increaseTime", [amount])
  await network.provider.send("evm_mine")
  // await network.provider.send("evm_setNextBlockTimestamp", [amount])
  // await network.provider.send("evm_mine")
  // console.log(`Moved forward ${amount} seconds`)
}

module.exports = { moveTime }
