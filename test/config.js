const testConfig = {
  name: 'alfajores',
  chainId: 44787,
  StableToken: '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1', // cUSD
  GoldToken: '0xF194afDf50B03e69Bd7D057c1Aa9e10c9954E4C9', // cGLD
  Exchange: '0x17bc3304F94c85618c46d0888aA937148007bD3C', // Exchange cUSD
  ExchangeEUR: '0x997B494F17D3c49E66Fafb50F37A972d8Db9325B', // Exchange cEUR
  ExchangeBRL: '0xf391DcaF77360d39e566b93c8c0ceb7128fa1A08', // Exchange cBRL
  MinGasPrice: '0xd0Bf87a5936ee17014a057143a494Dc5C5d51E5e', // MinGasPrice,
}

module.exports = Object.freeze(testConfig)
