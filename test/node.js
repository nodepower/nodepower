var node = artifacts.require('./Node.sol'),
    nodePhases = artifacts.require('./NodePhases.sol'),
    nodeAllocation = artifacts.require('./NodeAllocation.sol');

var Utils = require('./utils'),
    BigNumber = require('bignumber.js');

var precision = 100,
    now = parseInt(new Date().getTime() / 1000),
    bountyAddress = web3.eth.accounts[5],
    allocationAddress1 = web3.eth.accounts[6],
    allocationAddress2 = web3.eth.accounts[7],
    allocationAddress3 = web3.eth.accounts[8];

contract('Node', function (accounts) {
    let token;

    beforeEach(async function () {
        token = await node.new(
            new BigNumber(10000000).mul(precision),
            'NODE',
            'NODE',
            2,
            false
        )
    });

    it('deploy contract & check constructor data', async function () {

        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber('0').valueOf(), 'total supply is not equal')

        let maxSupply = await token.maxSupply.call()
        assert.equal(maxSupply.valueOf(), new BigNumber(10000000).mul(precision).valueOf(), 'max supply is not equal')

        let standard = await token.standard.call()
        assert.equal(standard.valueOf(), 'Node 0.1', 'standard is not equal')

        let name = await token.name.call()
        assert.equal(name.valueOf(), 'NODE', 'name is not equal')

        let symbol = await token.symbol.call()
        assert.equal(symbol.valueOf(), 'NODE', 'symbol is not equal')

        let decimals = await token.decimals.call()
        assert.equal(decimals.valueOf(), 2, 'decimals is not equal')

    });

    it('check setLocked, check if token transfers frozen', async function () {
        let phases = await nodePhases.new(
            token.address,
            new BigNumber(10).mul(precision),
            new BigNumber(3283559600000000),
            new BigNumber(750000).mul(precision),
            now - 3600 * 24 * 3,
            now - 3600 * 24 * 2,
            new BigNumber(0).mul(precision),
            new BigNumber(9800000).mul(precision),
            now - 3600 * 24,
            now - 3600
        )

        await token.setNodePhases(phases.address)

        await token.addMinter(phases.address);

        let locked = await token.locked.call()
        assert.equal(locked.valueOf(), false, 'locked is not equal')

        await token.setLocked(true, {from: accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)

        await token.setLocked(true)

        locked = await token.locked.call()
        assert.equal(locked.valueOf(), true, 'locked is not equal')

        await token.setLocked(false)

        locked = await token.locked.call()
        assert.equal(locked.valueOf(), false, 'locked is not equal')

        await token.mint(accounts[0], 10000)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 10000))

        await token.transfer(accounts[1], 1000)
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[1], 0))
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 10000))

        await token.transferFrom(accounts[0], accounts[1], 1000)
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[1], 0))
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 10000))

    })

    it('check setNodePhases, unfreeze, check if token transfers frozen', async function () {
        let phases = await nodePhases.new(
            token.address,
            new BigNumber(10).mul(precision),
            new BigNumber(3283559600000000),
            new BigNumber(750000).mul(precision),
            now - 3600 * 24 * 3,
            now - 3600 * 24 * 2,
            new BigNumber(1000000).mul(precision),
            new BigNumber(9800000).mul(precision),
            now - 3600 * 24,
            now - 3600
        )

        await token.setNodePhases(phases.address)

        await token.addMinter(phases.address);

        await Utils.getPhase(phases, 1)
            .then((phase) => Utils.checkPhase(
                phase,
                new BigNumber(3283559600000000),
                new BigNumber(10).mul(precision),
                new BigNumber(1000000).mul(precision),
                new BigNumber(9800000).mul(precision),
                now - 3600 * 24,
                now - 3600,
                false
            ))

        let transferFrozen = await token.transferFrozen.call()
        assert.equal(transferFrozen.valueOf(), true, 'transferFrozen is not equal')

        await token.unfreeze()

        transferFrozen = await token.transferFrozen.call()
        assert.equal(transferFrozen.valueOf(), false, 'transferFrozen is not equal')

        await token.mint(accounts[0], 10000)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 10000))

        await token.transfer(accounts[1], 1000)
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[1], 1000))
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 9000))

        await token.transferFrom(accounts[0], accounts[1], 1000)
            .catch(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[1], 1000))
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 9000))
    })

    it('check buyBack', async function () {
        let phases = await nodePhases.new(
            token.address,
            new BigNumber(10).mul(precision),
            new BigNumber(3283559600000000),
            new BigNumber(750000).mul(precision),
            now - 3600 * 24 * 3,
            now - 3600 * 24 * 2,
            new BigNumber(1000000).mul(precision),
            new BigNumber(9800000).mul(precision),
            now - 3600 * 24,
            now - 3600
        )

        await token.setNodePhases(phases.address)

        await token.addMinter(phases.address);

        let transferFrozen = await token.transferFrozen.call()
        assert.equal(transferFrozen.valueOf(), true, 'transferFrozen is not equal')

        await token.unfreeze()
            .then(() => Utils.balanceShouldEqualTo(token, token.address, 0))
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 0))

        transferFrozen = await token.transferFrozen.call()
        assert.equal(transferFrozen.valueOf(), false, 'transferFrozen is not equal')

        await token.mint(accounts[0], 10000)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 10000))

        let amount = await token.buyBack.call(accounts[0])
        assert.equal(amount.valueOf(), 10000, 'amount is not equal')

        await token.buyBack(accounts[0])
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], 0))
            .then(() => Utils.balanceShouldEqualTo(token, token.address, amount))
    })

});