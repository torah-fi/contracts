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
    // let oracle = "0x3aB76d4344fE2106837155D96b54EAD0bb8140Cf"
    let fxs = "0x59004773A3Af6671B7e2dC47aCba3e6b1DaEab31"
    let frax = "0xB4434520c08D3DD00D4BE1bC9063Cd557D17e19d"
    let pool = "0x618b5142Ca5804ABa43882c4Ae7a51D7AF5a9864"
    let lock = "0x85a549bd0Cca5B0ab930D62BAcb7a1aa3c3BF2aa"
    let swapMining = "0x27D801020b531154003ba9f31598FbBf3C0A1d01"


    for (const account of accounts) {
        //console.log('Account address' + account.address)
    }

    let deployer = accounts[0]
    console.log('deployer:' + deployer.address)
    // We get the contract to deploy
    console.log('Account balance:', (await deployer.getBalance()).toString() / 10 ** 18)

    //  const MintTool = await ethers.getContractFactory('MintTool', {
    //     libraries: {
    //         PoolLibrary: "0x6b60Ba3E76CaAD657D4A01dEd8Ee2c315ccF281A",
    //     },
    // });
    //
    //  mintTool = await MintTool.deploy(pool,frax, fxs,usdc);

    // console.log("mintTool:" + mintTool.address)


    // const LockerTool = await ethers.getContractFactory('LockerTool');
    //
    // lockerTool = await LockerTool.deploy(lock,"1800");
    // console.log("lockerTool:"+lockerTool.address)


    const CalcTool = await ethers.getContractFactory('CalcTool', {
        libraries: {
            PoolLibrary: "0x6b60Ba3E76CaAD657D4A01dEd8Ee2c315ccF281A",
        },
    });

    calcTool = await CalcTool.deploy(
        pool,
        frax,
        fxs,
        usdc,
        lock,
        "1800");
    console.log("calcTool:" + calcTool.address)

    // const CalcMiningReward = await ethers.getContractFactory('CalcMiningReward');
    //
    // calcMiningReward = await CalcMiningReward.deploy(swapMining);
    // console.log("calcMiningReward:"+calcMiningReward.address)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })