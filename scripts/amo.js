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
    let usdc = "0x488e9C271a58F5509e2868C8A758A345D28B9Db9"
    // let timeLock = " 0xf6d2Ac942b3C4a43F1936ab90249BB6d18E3b207"
    let tra = "0x8bd1652946B614ccfe7ADdFE1d55ef8be49D5B29"
    let rusd = "0x49FFC1e03D04986f646583E59D6e21ac193a4713"

    // let operatable = ""
    // let lock = ""
    let pool_usdc = "0xEa9aF56c345674B3485b870d03153878711c3a05"

    //


    for (const account of accounts) {
        //console.log('Account address' + account.address)
    }

    let deployer = accounts[0]
    console.log('deployer:' + deployer.address)
    // We get the contract to deploy
    console.log('Account balance:', (await deployer.getBalance()).toString() / 10 ** 18)

    //
    // const Locker = await ethers.getContractFactory('Locker');
    // lock = await Locker.deploy(tra, "300");
    // console.log("Locker:" + lock.address)

    // const GaugeFactory = await ethers.getContractFactory('GaugeFactory');
    // gaugeFactory = await GaugeFactory.deploy();
    // console.log("gaugeFactory:" + gaugeFactory.address)
    //
    // Boost = await ethers.getContractFactory("Boost");
    // boost = await Boost.deploy(
    //     operatable,
    //     lock,
    //     gaugeFactory.address,
    //     tra,
    //     toWei('1'),
    //     parseInt("10575868"),
    //     "1000"
    // );
    // console.log("boost:" + boost.address)


     const AMOMinter = await ethers.getContractFactory('AMOMinter');
        minterAmo = await AMOMinter.deploy(
            deployer.address,
            rusd,
            tra,
            usdc,
            pool_usdc
        );
        console.log("minterAmo:"+minterAmo.address)


    // await rusd.addPool(boost.address);



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })