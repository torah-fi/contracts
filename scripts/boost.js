const {expectRevert, time} = require('@openzeppelin/test-helpers');
const {toWei} = web3.utils;
// const Router = require('../test/mock/Timelock.json');
// const {BigNumber} = require('ethers');

// const Timelock = require('../test/mock/Timelock.json');
const {deployContract, MockProvider, solidity, Fixture} = require('ethereum-waffle');
const {ethers, waffle} = require("hardhat");


function encodeParameters(types, values) {
    const abi = new ethers.utils.AbiCoder();
    return abi.encode(types, values);
}

async function main() {
    const accounts = await ethers.getSigners()
    const zeroAddr = "0x0000000000000000000000000000000000000000"
    //let usdc = ""
    // let timeLock = " 0xf6d2Ac942b3C4a43F1936ab90249BB6d18E3b207"
    let TRA = "0x59004773A3Af6671B7e2dC47aCba3e6b1DaEab31"
    // let frax = "0xa0fec666998754149132F2B49DAeEE484B522df7"
    // //
    // // let operatable = "0xb9F6ED924F0b46fA9912eBc62BcBeB64FbFcC005"
    let checkPermission = "0xDd3325440F70F590B8011b8C557c26242595E34F"
    let lock = "0x85a549bd0Cca5B0ab930D62BAcb7a1aa3c3BF2aa"
    //let gaugeFactory ="0x83F341cAd69720f339e1d5280Ba0B242969328c5"
    let boost = "0x47f4454c282F010AEe6aAe5E0208E52A329180c8"
    let weth9 = "0xABD262d7E300B250bab890f5329E817B7768Fe3C"

    for (const account of accounts) {
        //console.log('Account address' + account.address)
    }

    let deployer = accounts[0]
    console.log('deployer:' + deployer.address)
    // We get the contract to deploy
    console.log('Account balance:', (await deployer.getBalance()).toString() / 10 ** 18)


    // const TestOracle = await ethers.getContractFactory("TestOracle");
    // oracle = await TestOracle.deploy();
    // console.log("oracle:" + oracle.address);
    //
    //  const Operatable = await ethers.getContractFactory('Operatable');
    //  operatable = await Operatable.deploy();
    //  console.log("operatable:" + operatable.address)
    //
    // const FRAXShares = await ethers.getContractFactory('Stock');
    // TRA = await FRAXShares.deploy(operatable.address, "TRA", "TRA", oracle.address);
    // console.log("TRA:" + TRA.address);
    //


    // const Operatable = await ethers.getContractFactory("Operatable");
    // operatable = await Operatable.deploy();
    //  console.log("operatable:" + operatable.address);
    //
    //
    // const CheckPermission = await ethers.getContractFactory("CheckPermission");
    // checkPermission = await CheckPermission.deploy(operatable.address);
    //  console.log("checkPermission:" + checkPermission.address);
    //
    // const FRAXStablecoin = await ethers.getContractFactory('RStablecoin');
    // frax = await FRAXStablecoin.deploy(checkPermission.address, "frax", "frax");
    // console.log("frax:" + frax.address);
    //
    //  const FRAXShares = await ethers.getContractFactory('Stock');
    // TRA = await FRAXShares.deploy(checkPermission.address, "TRA", "TRA", oracle.address);
    // console.log("TRA:" + TRA.address);
    //
    //
    // await TRA.setStableAddress(frax.address);
    // await frax.setStockAddress(TRA.address);
    //
    //
    // const Locker = await ethers.getContractFactory('Locker');
    // lock = await Locker.deploy(checkPermission, TRA, "1800");
    // console.log("Locker:" + lock.address)
    //
    // const GaugeFactory = await ethers.getContractFactory('GaugeFactory');
    // gaugeFactory = await GaugeFactory.deploy(checkPermission);
    // console.log("gaugeFactory:" + gaugeFactory.address)

    //  Boost = await ethers.getContractFactory("Boost");
    //  boost = await Boost.deploy(
    //      checkPermission,
    //      lock,
    //      gaugeFactory,
    //      TRA,
    //      toWei('1'),
    //      parseInt("19204972"),
    //      "2592000"
    //  );
    // console.log("boost:" + boost.address)


    const GaugeController = await ethers.getContractFactory('GaugeController');
    gaugeController = await GaugeController.deploy(
        checkPermission,
        boost,
        lock,
        "1200");

    console.log("gaugeController:" + gaugeController.address)
    const SwapRouter = await ethers.getContractFactory('SwapRouter');
    swapRouter = await SwapRouter.deploy(checkPermission, weth9);
    console.log("swapRouter:" + swapRouter.address);


    const SwapMining = await ethers.getContractFactory('SwapMining');
    swapMining = await SwapMining.deploy(
        checkPermission,
        lock,
        TRA,
        deployer.address,
        swapRouter.address,
        toWei('1'),
        "19205084",
        "259200"
    );
    console.log("swapMining:" + swapMining.address);
    await swapRouter.setSwapMining(swapMining.address);


    const SwapController = await ethers.getContractFactory('SwapController');
    swapController = await SwapController.deploy(
        checkPermission,
        swapMining.address,
        lock,
        "1200");

    console.log("swapController:" + swapController.address)

    // await boost.addController(gaugeController.address);
    // // await lock.removeBoosts(boost.address)
    // await lock.addBoosts(gaugeController.address);

    // await lock.addBoosts(boost.address)
    // await TRA.addPool(boost.address);


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })