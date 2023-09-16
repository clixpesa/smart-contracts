module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('TestInterest', {
    from: deployer,
    log: true,
  })

  await deploy('P2PLoans', {
    from: deployer,
    log: true,
  })

  await deploy('PersonalSpaces', {
    from: deployer,
    log: true,
  })
}
module.exports.tags = ['TestInterest', 'P2PLoans', 'PersonalSpaces']
