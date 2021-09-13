require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('hardhat-deploy');

require('dotenv').config();

const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL;
const MNEMONIC = process.env.MNEMONIC;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {},
    rinkeby: {
      url: RINKEBY_RPC_URL,
      accounts: {
        mnemonic: MNEMONIC,
      },
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  solidity: {
    compilers: [
      { version: '0.8.0' },
      { version: '0.4.24' },
      { version: '0.6.6' },
      { version: '0.7.0' },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};
