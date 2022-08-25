require('dotenv').config();
const hre = require('hardhat');

//SplitPluginFactory contract address needs to update properties.
const SplitPluginFactory = '';

async function main() {
  const ethers = hre.ethers;
  const network = await ethers.provider.getNetwork();
  console.log('network:', await ethers.provider.getNetwork());

  const signer = (await ethers.getSigners())[0];
  console.log('signer:', await signer.getAddress());

  const SplitPluginFactoryProperty = await ethers.getContractFactory('SplitPluginFactory', { signer: (await ethers.getSigners())[0] });
  const UpdatePropertySplitPluginFactory = await SplitPluginFactoryProperty.attach(SplitPluginFactory);

  const flagUpdate = {
    updateSharedOwner: false,
    transferOwnership: false,
    updateSplitPluginImpl: false //Be careful when using this function!!!
  };

  // console.log(UpdatePropertySplitPluginFactory);

  /**
   * update updateSharedOwner
   */
  if (flagUpdate.updateSharedOwner) {
    console.log('Start updateSharedOwner...');
    const newSharedOwner = ''; // new SharedOwner address
    const tx = await UpdatePropertySplitPluginFactory.updateSharedOwner(newSharedOwner);
    console.log('updateSharedOwner' + ': ' + newSharedOwner + ' to SplitPluginFactory');
    await tx.wait();
    console.log('Done for: ' + newSharedOwner);
    console.log('Done updateSharedOwner...');
  }

  /**
   * update updateSplitPluginImpl
   */
  if (flagUpdate.updateSplitPluginImpl) {
    console.log('Start updateS plitPluginImpl...');
    const newSplitPluginImpl = ''; // new SplitPluginImpl
    const tx = await UpdatePropertySplitPluginFactory.updateSplitPluginImpl(newSplitPluginImpl);
    console.log('updateSplitPluginImpl' + ': ' + newSplitPluginImpl + ' to SplitPluginFactory');
    await tx.wait();
    console.log('Done for: ' + newSplitPluginImpl);
    console.log('Done updateSplitPluginImpl.');
  }

  // /**
  //  * update transferOwnership
  //  */
  //  if (flagUpdate.transferOwnership) {
  //   console.log('Start transferOwnership...');
  //   const newOwner = ''; // new Owner address
  //   const tx = await UpdatePropertySplitPluginFactory.transferOwnership(newOwner);
  //   console.log('transferOwnership' + ': ' + newOwner + ' to SplitPluginFactory');
  //   await tx.wait();
  //   console.log('Done for: ' + newOwner);
  //   console.log('Done transferOwnership.');
  // }

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })