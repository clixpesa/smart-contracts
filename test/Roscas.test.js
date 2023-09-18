const { ethers, artifacts } = require('hardhat')
const { expect } = require('chai')
const stableTokenAbi = require('./stableToken.json')
const {customAlphabet} = require('nanoid')
const nanoid = customAlphabet('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', 10)
const config = require('./config.js')
const { time } = require('@nomicfoundation/hardhat-network-helpers')
const exp = require('constants')

describe('Clixpesa Rosca Spaces', function () {
  let RoscaSpaces, RoscaSpacesIface, Rosca, RoscaIface, Token, addr1, addr2, addr3, inviteCode, tokenDecimals
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
      goalAmount: ethers.utils.parseUnits('0.2', tokenDecimals).toString(),
      ctbAmount: ethers.utils.parseUnits('0.1', tokenDecimals).toString(),
      ctbDay: 'Sunday',
      disbDay: 'Monday',
      occurrence: 'Weekly',
    }
    inviteCode = nanoid()
    const txResponse = await RoscaSpaces.createRoscaSpace(Object.values(roscaDetails), inviteCode)
    const txReceipt = await txResponse.wait()
    const thisLog = txReceipt.logs.find((el) => el.address === RoscaSpaces.address)
    const results = RoscaSpacesIface.parseLog({ data: thisLog.data, topics: thisLog.topics })
    expect(results.args.roscaName).to.be.equal(roscaDetails.roscaName)
    Rosca = await ethers.getContractAt('Rosca', results.args.roscaAddress)
    const roscaDetailsFrom = await Rosca.getRoscaDetails()
    expect(roscaDetailsFrom.creator).to.be.equal(addr1.address)
    
  })

  it('ADD2 Should join the rosca', async function () {
    const txResponse = await Rosca.connect(addr2).joinRosca(inviteCode)
    const txReceipt = await txResponse.wait()
    const thisLog = txReceipt.logs.find((el) => el.address === Rosca.address)
    const results = RoscaIface.parseLog({ data: thisLog.data, topics: thisLog.topics })
    expect(results.args.memberAddress).to.be.equal(addr2.address)
    const members = await Rosca.getMembers()
    expect(members.length).to.be.equal(2)
  })

  it('Should return next contribution date', async function () {
    const nextContributionDate = await Rosca.nextPot()
    console.log(nextContributionDate)
  })

  it('Should get current potDetails', async function () {
    const potDetails = await Rosca.getCurrentPotDetails()
    expect(potDetails.potAmount).to.be.equal(ethers.utils.parseUnits('0.2', tokenDecimals).toString())
    expect(potDetails.potOwner).to.be.equal(addr1.address)
  })

  it("ADD2 Should contribute to the pot", async function () {
    const ctbAmount = ethers.utils.parseUnits('0.1', tokenDecimals).toString()
    await Token.connect(addr2).approve(Rosca.address, ctbAmount)
    await delay(5000)
    const txResponse = await Rosca.connect(addr2).contributeToPot(ctbAmount)
    const txReceipt = await txResponse.wait()
    const thisLog = txReceipt.logs.find((el) => el.address === Rosca.address)
    const results = RoscaIface.parseLog({ data: thisLog.data, topics: thisLog.topics })
    expect(results.args.memberAddress).to.be.equal(addr2.address)
    expect(results.args.amount).to.be.equal(ctbAmount)
    const potDetails = await Rosca.getCurrentPotDetails()
    expect(potDetails.potBalance).to.be.equal(ctbAmount)
    const newRoscaBal = await Token.balanceOf(Rosca.address)
    expect(newRoscaBal).to.be.equal(ctbAmount)
  })
}) 