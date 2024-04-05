async function verify(contractAddress, args) {
  console.log("---------------Verifying contract----------------- ")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    })
  } catch (e) {
    if (e.message.toLowerCase().includes("already verify")) {
      console.log("Already Verify")
    } else {
      console.log(e)
    }
  }
}

module.exports = { verify }
