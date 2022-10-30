const $ = require('../util/provider');
const {expect} = require('chai');
const {time} = require("@openzeppelin/test-helpers");
const {toWei, fromWei, toBN} = require("web3-utils");
const {BigNumber} = require("ethers");

describe('Stock Test', () => {

    let _zeroAddress;

    beforeEach(async () => {
        [owner, dev] = await ethers.getSigners();

        const {
            zeroAddress,
            Operatable, CheckPermission, Stock,
            Locker, Boost, Gauge, GaugeController, GaugeFactory
        } = await $.setup();
        _zeroAddress = zeroAddress;

        token0 = await $.mockToken("token0", "token0", 18, toWei("0"));
        await token0.mint(owner.address, toWei("10000"));

        operatable = await Operatable.deploy();
        checkPermission = await CheckPermission.deploy(operatable.address);

        stock = await Stock.deploy(checkPermission.address, "stock", "stock");

        let _duration = await time.duration.days(1);
        locker = await Locker.deploy(checkPermission.address, stock.address, parseInt(_duration));

        gaugeFactory = await GaugeFactory.deploy(checkPermission.address);

        let _period = await time.duration.days(1);
        let block = await time.latestBlock();
        boost = await Boost.deploy(
            checkPermission.address,
            locker.address,
            gaugeFactory.address,
            stock.address,
            toWei("1"),
            parseInt(block),
            parseInt(_period));

        await stock.addPool(boost.address);
        await stock.approve(locker.address, toWei('10000'));

        _duration = await boost.mintDuration();
        gaugeController = await GaugeController.deploy(
            checkPermission.address,
            boost.address,
            locker.address,
            _duration
        );
        await gaugeController.setDuration(_duration);
        await gaugeController.addPool(token0.address);
        expect(await gaugeController.getPool(0)).to.be.eq(token0.address);

        await boost.createGauge(token0.address, "100", true);
        const gaugeAddress = await boost.gauges(token0.address);
        gauge = await Gauge.attach(gaugeAddress);
        expect(gaugeAddress).to.be.eq(gauge.address);

        await locker.createLock(toWei("1000"), _duration);
        tokenId = await locker.tokenId();
        expect(tokenId).to.be.eq(1);

        await token0.approve(gaugeAddress, toWei("10000"));

        await boost.addController(gaugeController.address);
        await locker.addBoosts(gaugeController.address);
        await locker.addBoosts(boost.address);
    });

    it('test deposit stock mint', async () => {
        let stockTotalBef = await stock.totalSupply();

        let stockBef = await stock.balanceOf(owner.address);
        let token0Bef = await token0.balanceOf(owner.address);

        expect(stockBef).to.be.eq("349999000000000000000000000");
        expect(token0Bef).to.be.eq(toWei("10000"));

        // increase block reward
        await boost.setTokenPerBlock(toWei("1000"), true);
        await gauge.updatePool();
        let blockBef = await time.latestBlock();

        await gauge.deposit(toWei("1000"));

        let stockAft = await stock.balanceOf(owner.address);
        let token0Aft = await token0.balanceOf(owner.address);

        expect(stockAft).to.be.eq(stockBef);
        expect(token0Aft).to.be.eq(BigNumber.from(token0Bef).sub(toWei("1000")));

        await boost.massUpdatePools();
        let blockAft = await time.latestBlock();
        let expectReward = (blockAft - blockBef + 1) * 1000 * 0.3;

        await gauge.getReward(owner.address);

        let stockAft1 = await stock.balanceOf(owner.address);
        let actualReward = BigNumber.from(fromWei(toBN(stockAft1))).sub(fromWei(toBN(stockAft)));

        expect(actualReward).to.be.eq(expectReward);

        let stockTotalAft = await stock.totalSupply();

        expect(stockTotalAft).to.be.gt(stockTotalBef);
    });

    it('test add pool', async () => {
        expect(await stock.poolAddressCount()).to.be.eq(1);

        await expect(stock.addPool(boost.address)).to.be.revertedWith("Address already exists");

        await expect(stock.removePool(boost.address)).to.be.emit(stock, 'PoolRemoved').withArgs(boost.address);

        await expect(stock.addPool(boost.address)).to.be.emit(stock, "PoolAdded").withArgs(boost.address);
    });
});