// const path = require('path');
// const envPath = path.join(__dirname, '../../.env');
// require('dotenv').config({ path: envPath });
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
// require("hardhat-gas-reporter");
// require('solidity-coverage');
// require("@nomiclabs/hardhat-vyper");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async () => {
//   const accounts = await ethers.getSigners();
//
//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            allowUnlimitedContractSize: false,
        },
        testnet: {
            url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
            chainId: 97,
            gasPrice: 60000000000,
            accounts: ['a169188d442a35eff327a448d864d82523f95e07a20e76247230ba38c596d0dd'],
        },
        mainnet: {
            url: 'https://bsc-dataseed.binance.org/',
            chainId: 56,
            accounts: ['f8ed8ab1fa0edebd1281d9685752aadbd0e34c9248e67757400c5a4b711a8153']
            // gasPrice: 20000000000,
            // accounts: {mnemonic: mnemonic}
        },
        ethtest: {
            url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
            chainId: 4,
            accounts: ['a169188d442a35eff327a448d864d82523f95e07a20e76247230ba38c596d0dd']
            // gasPrice: 20000000000,
            // accounts: {mnemonic: mnemonic}
        },
         kccTest: {
            url: 'https://rpc-testnet.kcc.network',
            chainId: 322,
            accounts: ['a169188d442a35eff327a448d864d82523f95e07a20e76247230ba38c596d0dd']
            // gasPrice: 20000000000,
            // accounts: {mnemonic: mnemonic}
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.5.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            {
                version: "0.6.11",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            {
                version: "0.7.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            // {
            // 	version: "0.8.0",
            // 	settings: {
            // 		optimizer: {
            // 			enabled: true,
            // 			runs: 100000
            // 		}
            // 	  }
            // },
            // {
            // 	version: "0.8.2",
            // 	settings: {
            // 		optimizer: {
            // 			enabled: true,
            // 			runs: 100000
            // 		}
            // 	  }
            // },
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            {
                version: "0.8.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100000
                    }
                }
            },
            {
                version: "0.8.10",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200
                    }
                }
            }
        ],
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 500000
    },
    // etherscan: {
    // 	// apiKey: process.env.BSCSCAN_API_KEY // BSC
    // 	apiKey: process.env.ETHERSCAN_API_KEY, // ETH Mainnet
    // 	// apiKey: process.env.FTMSCAN_API_KEY // Fantom
    // 	// apiKey: process.env.OPTIMISM_API_KEY, // Optimism
    // 	// apiKey: process.env.POLYGONSCAN_API_KEY // Polygon
    // },

    contractSizer: {
        alphaSort: true,
        runOnCompile: true,
        disambiguatePaths: false,
    },
    // vyper: {
    // 	// version: "0.2.15"
    // 	// version: "0.2.16"
    // 	version: "0.3.1"
    // }
};

