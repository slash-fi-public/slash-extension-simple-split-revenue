require('dotenv').config()
const hre = require('hardhat')

const sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay * 1000));

async function main() {
  const ethers = hre.ethers
  const upgrades = hre.upgrades;

  console.log('network:', await ethers.provider.getNetwork())

  const signer = (await ethers.getSigners())[0]
  console.log('signer:', await signer.getAddress())

  const deployFlag = {
    verifyFactory: false,
    deployPluginTemplate: false,
    deployNftPluginTemplate: false,
    clonePlugin: false,
    cloneNftPlugin: true,
    deployFactory: false,
    upgradeFactory: false,
  };

  /**
   * Verify Factory
   */
  if (deployFlag.verifyFactory) {
    const factoryImplAddress = '0xe431b86d05288ba0b2b05ca395b412b6824cf25e';

    await hre.run('verify:verify', {
      address: factoryImplAddress,
      constructorArguments: []
    })

    console.log("SplitFactory at: ", factoryImplAddress, " verified");
  }

  /**
   * Deploy SplitPlugin Template
   */
  if (deployFlag.deployPluginTemplate) {
    const SplitPlugin = await ethers.getContractFactory('contracts/v2/plugins/SplitPlugin.sol:SplitPlugin', { signer: (await ethers.getSigners())[0] })

    const pluginContract = await SplitPlugin.deploy();
    await pluginContract.deployed();
    await sleep(30);
    console.log("SplitPlugin template deployed to: ", pluginContract.address);

    await hre.run('verify:verify', {
      address: pluginContract.address,
      constructorArguments: []
    })
    console.log('SplitPlugin template verified', pluginContract.address)
  }

  /**
 * Deploy NftSplitPlugin Template
 */
  if (deployFlag.deployNftPluginTemplate) {
    const NftSplitPlugin = await ethers.getContractFactory('contracts/v2/plugins/NftSplitPlugin.sol:NftSplitPlugin', { signer: (await ethers.getSigners())[0] })

    const pluginContract = await NftSplitPlugin.deploy();
    await pluginContract.deployed();
    await sleep(30);
    console.log("NftSplitPlugin template deployed to: ", pluginContract.address);

    await hre.run('verify:verify', {
      address: pluginContract.address,
      constructorArguments: []
    })
    console.log('NftSplitPlugin template verified', pluginContract.address)
  }

  /**
   *  Deploy SplitPlugin Factory
   */
  if (deployFlag.deployFactory) {
    const sharedOwner = '0x172A25d57dA59AB86792FB8cED103ad871CBEf34';
    const splitPluginTemplate = '0xaEEE5141Ebe87e05b57e30841e9Eb3e4715F541D';
    const nftSplitPluginTemplate = '0x137ECBB48Dd0A98534cdF2aa5758A46231F0b12E';

    const SplitPluginFactory = await ethers.getContractFactory('contracts/v2/plugins/SplitPluginFactory.sol:SplitPluginFactory', {
      signer: (await ethers.getSigners())[0]
    });
    const factoryProxyContract = await upgrades.deployProxy(SplitPluginFactory, [sharedOwner, splitPluginTemplate, nftSplitPluginTemplate], { initializer: 'initialize' });
    await factoryProxyContract.deployed()

    console.log('SplitPluginFactory proxy deployed: ', factoryProxyContract.address)
  }

  /**
   * Upgrade SplitPlugin Factory
   */
  if (deployFlag.upgradeFactory) {
    const factoryAddress = "0x302e983947E1D03Dd08048A1c5ef04364A01d1B3";

    const SplitPluginFactoryV2 = await ethers.getContractFactory('contracts/v2/plugins/SplitPluginFactory.sol:SplitPluginFactory', {
      signer: (await ethers.getSigners())[0]
    })

    const upgradedFactoryContract = await upgrades.upgradeProxy(factoryAddress, SplitPluginFactoryV2);
    console.log('SplitPluginFactory proxy upgraded: ', upgradedFactoryContract.address)
  }

  /**
   * Clone SplitPLugin from Factory
   */
  if (deployFlag.clonePlugin) {
    const factoryAddress = '0x302e983947E1D03Dd08048A1c5ef04364A01d1B3';
    const splitWallets = ['0x19E53469BdfD70e103B18D9De7627d88c4506DF2', '0x7861e0f3b46e7C4Eac4c2fA3c603570d58bd1d97', '0xDF1A23195c13ea380E00DEe2e7f4c8d3b4b7Ef17'];
    const splitRates = [2500, 3000, 4500];

    const SplitPluginFactory = await ethers.getContractFactory('contracts/v2/plugins/SplitPluginFactory.sol:SplitPluginFactory', { signer: (await ethers.getSigners())[0] });
    const pluginFactory = await SplitPluginFactory.attach(factoryAddress);

    const tx = await pluginFactory.deploySplitPlugin(splitWallets, splitRates);
    await tx.wait();
    console.log('Plugin Cloned');
  }

  /**
   * Clone NftSplitPLugin from Factory
   */
  if (deployFlag.cloneNftPlugin) {
    const factoryAddress = '0x302e983947E1D03Dd08048A1c5ef04364A01d1B3';
    
    const SplitPluginFactory = await ethers.getContractFactory('contracts/v2/plugins/SplitPluginFactory.sol:SplitPluginFactory', { signer: (await ethers.getSigners())[0] });
    const pluginFactory = await SplitPluginFactory.attach(factoryAddress);

    const tx = await pluginFactory.deployNftSplitPlugin();
    await tx.wait();
    console.log('Plugin Cloned');
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
