require('dotenv').config()
require('@nomiclabs/hardhat-ethers')
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_NODE_URL,
      accounts: [process.env.ROPSTEN_PRIVATE_KEY]
    },
    rinkeby: {
      url: process.env.RINKEBY_NODE_URL,
      accounts: [process.env.RINKEBY_PRIVATE_KEY]
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.4',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ]
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
}
