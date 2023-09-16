const { ethers, artifacts } = require('hardhat')
const { expect } = require('chai')
const stableTokenAbi = require('./stableToken.json')
const {customAlphabet} = require('nanoid')
const nanoid = customAlphabet('1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', 10)
const config = require('./config.js')
const { time } = require('@nomicfoundation/hardhat-network-helpers')

describe('Clixpesa Interest', function () {
  let TestInterest, TestInterestIface
  const delay = (ms) => {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }

  before(async () => {
    const loansContract = await ethers.getContractFactory('TestInterest')
    const signers = await ethers.getSigners()
    addr1 = signers[0]
    TestInterest = await loansContract.deploy()
    TestInterestIface = new ethers.utils.Interface((await artifacts.readArtifact('TestInterest')).abi)
    await TestInterest.deployed()
  })

  it('Should return some accrued Interest', async function () {
    const amount = ethers.utils.parseEther('100')
    const txResponse = await TestInterest.getInterest(amount, 600, 1694823780)
    console.log(ethers.utils.formatUnits(txResponse.toString(), 18))
  })

})