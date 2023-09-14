module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  await deploy('P2PLoans', {
    from: deployer,
    log: true,
  })
}
module.exports.tags = ['P2PLoans']
