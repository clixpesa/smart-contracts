const { ethers, artifacts } = require('hardhat')
const { expect } = require('chai')
const stableTokenAbi = require('./stableToken.json')
const {customAlphabet} = require('nanoid')
const nanoid = customAlphabet('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', 10)
const config = require('./config.js')
const { time } = require('@nomicfoundation/hardhat-network-helpers')

describe('Clixpesa Rosca Spaces', function () {
  let RoscaSpaces, RoscaSpacesIface, Rosca, RoscaIface, Token, addr1, addr2, addr3
  const delay = (ms) => {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }

  before(async () => {
    const loansContract = await ethers.getContractFactory('RoscaSpaces')
    Token = await ethers.getContractAt(stableTokenAbi, config.StableToken)
    tokenDecimals = await Token.decimals()
    const signers = await ethers.getSigners()
    addr1 = signers[0]
    addr2 = signers[1]
    addr3 = signers[2]

    RoscaSpaces = await loansContract.deploy()
    RoscaSpacesIface = new ethers.utils.Interface((await artifacts.readArtifact('RoscaSpaces')).abi)
    await RoscaSpaces.deployed()

    RoscaIface = new ethers.utils.Interface((await artifacts.readArtifact('Rosca')).abi)
  })

  it('Should create a rosca named Wajackoyas', async function () {
    const roscaDetails = {
      token: Token.address,
      roscaName: 'Wajackoyas',
      imgLink: 'bit.ly/hthfdrer',
      authCode: nanoid(),
      goalAmount: ethers.utils.parseUnits('0.2', 6).toString(),
      ctbAmount: ethers.utils.parseEther('0.1', 6).toString(),
      ctbDay: 'Sunday',
      ctbOccurence: 'Weekly',
      disbDay: 'Monday',
      disbOccurence: 'Weekly',
    }

    const txResponse = await RoscaSpaces.createRoscaSpace(Object.values(roscaDetails))
    const txReceipt = await txResponse.wait()
    const thisLog = txReceipt.logs.find((el) => el.address === RoscaSpaces.address)
    const results = RoscaSpacesIface.parseLog({ data: thisLog.data, topics: thisLog.topics })
    Rosca = await ethers.getContractAt('Rosca', results.args.roscaAddress)

    expect(results.args.roscaName).to.be.equal(roscaDetails.roscaName)
  })
}) 