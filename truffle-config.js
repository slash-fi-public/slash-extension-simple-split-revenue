const os = require('os');
// console.log("os platform = ", os.platform());
let apiKey;
let slash = os.platform() === "win32" ? '\\' : '/';
try {
	console.log(`Loading etherscan key from ${os.homedir() + slash + ".ethereum" + slash + "etherscan.json"}`);
	apiKey = require(os.homedir() + slash + ".ethereum" + slash + "etherscan.json").apiKey;
	console.log("loaded etherscan api key");
} catch {
	console.log("unable to load etherscan key from config")
	apiKey = "UNKNOWN"
}

function createNetwork(name) {
  try {
    var json = require(os.homedir() + slash + ".ethereum" + slash + name + ".json");
    var gasPrice = json.gasPrice != null ? json.gasPrice : 2000000000;

    return {
      provider: () => createProvider(json.address, json.key, json.url),
      from: json.address,
      gas: 6000000,
      gasPrice: gasPrice + "000000000",
      network_id: json.network_id,
      skipDryRun: true,
      networkCheckTimeout: 500000
    };
  } catch (e) {
    return null;
  }
}

function createProvider(address, key, url) {
  // console.log("creating provider for address: " + address);
  var HDWalletProvider = require("@truffle/hdwallet-provider");
  return new HDWalletProvider(key, url);
}

module.exports = {
	api_keys: {
    etherscan: apiKey
  },

	plugins: [
    'truffle-plugin-verify',
    'truffle-contract-size'
  ],

  networks: {
    e2e: createNetwork("e2e"),
    ops: createNetwork("ops"),
    ropsten: createNetwork("ropsten"),
    mainnet: createNetwork("mainnet"),
    rinkeby: createNetwork("rinkeby"),
    rinkeby2: createNetwork("rinkeby2"),
    polygon_mumbai: createNetwork("polygon_mumbai"),
    fantom: createNetwork("fantom"),
    kovan: createNetwork("kovan")
  },

  compilers: {
    solc: {
      version: "0.8.3",
      settings: {
        optimizer: {
          enabled : true,
          runs: 100
        },
        evmVersion: "istanbul"
      }
    }
  }
}
