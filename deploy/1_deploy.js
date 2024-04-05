module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()

  log("----------------------------------------------------")
  log("IcoToken")
  // log("----------------------------------------------------")
  const arguments = ["IcoToken", "ITK", "1000"]
  const icoToken = await deploy("IcoToken", {
    from: deployer,
    args: arguments,
    log: true,
    //waitConfirmations: network.config.blockConfirmations || 1,
  })
}

module.exports.tags = ["all", "icoToken"]
