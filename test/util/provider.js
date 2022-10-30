const {ethers} = require("hardhat");
const {deployContract} = require("ethereum-waffle");


const setup = async () => {
    const zeroAddress = "0x0000000000000000000000000000000000000000";

    const contracts = {
        MockToken: await ethers.getContractFactory('MockToken'),
        CheckPermission: await ethers.getContractFactory('CheckPermission'),
        Operatable: await ethers.getContractFactory('Operatable'),
        Stock: await ethers.getContractFactory('Stock'),
        Locker: await ethers.getContractFactory('Locker'),
        Boost: await ethers.getContractFactory('Boost'),
        Gauge: await ethers.getContractFactory('Gauge'),
        GaugeController: await ethers.getContractFactory('GaugeController'),
        GaugeFactory: await ethers.getContractFactory('GaugeFactory'),
    }

    return {
        ...contracts,
        zeroAddress,
    }
}

const deploy = async (owner, bytecode, abi, args = []) => {
    return await deployContract(owner, {
        bytecode: bytecode,
        abi: abi
    }, args);
}

const mockToken = async (name, symbol, decimals, total) => {
    const MockToken = await ethers.getContractFactory("MockToken");
    return await MockToken.deploy(name, symbol, decimals, total);
}

const mockTokenBatch = async (decimals, total, ...names) => {
    let arr = [];
    for (let item of names) {
        arr.push(await mockToken(item, item, decimals, total));
    }
    return arr;
}

const ethBalance = async (address) => {
    return web3.eth.getBalance(address);
}

const log = (tag, data) => {
    console.log("" + tag + ": " + data);
}

module.exports = {
    setup,
    deploy,
    mockToken,
    mockTokenBatch,
    ethBalance,
    log
}
