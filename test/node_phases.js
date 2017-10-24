var node = artifacts.require("./Node.sol");
var nodePhases = artifacts.require("./NodePhases.sol");
var nodeAllocation = artifacts.require("./NodeAllocation.sol");

var Utils = require("./Utils"),
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

    // it('deploy contract & check constructor data', async function () {
    //
    //     let phases = await nodePhases.new(
    //         token.address,
    //         new BigNumber(10).mul(precision),
    //         new BigNumber(3283559600000000),
    //         new BigNumber(750000).mul(precision),
    //         now - 3600 * 24 * 1,
    //         now + 3600 * 24 * 1,
    //         new BigNumber(1000000).mul(precision),
    //         new BigNumber(9800000).mul(precision),
    //         now + 3600 * 24 * 2,
    //         now + 3600 * 24 * 3
    //     )
    //
    //     await Utils.getPhase(phases, 0)
    //         .then((phase) => Utils.checkPhase(
    //             phase,
    //             new BigNumber(3283559600000000),
    //             new BigNumber(10).mul(precision),
    //             0,
    //             new BigNumber(750000).mul(precision),
    //             now - 3600 * 24 * 1,
    //             now + 3600 * 24 * 1,
    //             false
    //         ))
    //
    //     await Utils.getPhase(phases, 1)
    //         .then((phase) => Utils.checkPhase(
    //             phase,
    //             new BigNumber(3283559600000000),
    //             new BigNumber(10).mul(precision),
    //             new BigNumber(1000000).mul(precision),
    //             new BigNumber(9800000).mul(precision),
    //             now + 3600 * 24 * 2,
    //             now + 3600 * 24 * 3,
    //             false
    //         ))
    // });
    //
    // it("create contract & buy tokens preico & check bonus & check ethers", async function () {
    //     let phases = await nodePhases.new(
    //         token.address,
    //         new BigNumber(10).mul(precision),
    //         new BigNumber(3283559600000000),
    //         new BigNumber(750000).mul(precision),
    //         now - 3600 * 24 * 1,
    //         now + 3600 * 24 * 1,
    //         new BigNumber(1000000).mul(precision),
    //         new BigNumber(9800000).mul(precision),
    //         now + 3600 * 24 * 2,
    //         now + 3600 * 24 * 3
    //     )
    //
    //     let allocation = await nodeAllocation.new(
    //         bountyAddress,
    //         [allocationAddress1, allocationAddress2],
    //         [allocationAddress1, allocationAddress2, allocationAddress3],
    //         [new BigNumber(1000000).mul(precision), new BigNumber(3000000).mul(precision), new BigNumber(5000000).mul(precision), new BigNumber(7000000).mul(precision)]
    //     )
    //
    //     let allocationAddress1Balance = Utils.getEtherBalance(allocationAddress1),
    //         allocationAddress2Balance = Utils.getEtherBalance(allocationAddress2);
    //
    //     await token.addMinter(phases.address);
    //
    //     await phases.setNodeAllocation(allocation.address)
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("45681").valueOf()))
    //
    //     let collectedEthers = await phases.getBalanceContract()
    //     assert.equal(collectedEthers.valueOf(), "1000000000000000000", 'collectedEthers is not equal')
    //
    //     //1000000000000000000 * 100 / 3283559600000000 = 30454.7540419 | 30454.7540419 * 50 / 100 = 15227.377021 | 45682.1310629
    //     let soldTokens = await phases.getTokens()
    //     assert.equal(soldTokens.valueOf(), "45681", 'soldTokens is not equal')
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("30000000000000000").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("970000000000000000").add(allocationAddress2Balance))
    //
    // });
    //
    // it("create contract & buy tokens ico & check bonus for first period & check ethers", async function () {
    //     let phases = await nodePhases.new(
    //         token.address,
    //         new BigNumber(10).mul(precision),
    //         new BigNumber(3283559600000000),
    //         new BigNumber(750000).mul(precision),
    //         now - 3600 * 24 * 13,
    //         now - 3600 * 24 * 12,
    //         new BigNumber(1000000).mul(precision),
    //         new BigNumber(9800000).mul(precision),
    //         now - 3600 * 24 * 10,
    //         now + 3600 * 24 * 30
    //     )
    //
    //     let allocation = await nodeAllocation.new(
    //         bountyAddress,
    //         [allocationAddress1, allocationAddress2],
    //         [allocationAddress1, allocationAddress2, allocationAddress3],
    //         [new BigNumber(50000), new BigNumber(3000000).mul(precision), new BigNumber(5000000).mul(precision), new BigNumber(7000000).mul(precision)]
    //     )
    //
    //     let allocationAddress1Balance = Utils.getEtherBalance(allocationAddress1),
    //         allocationAddress2Balance = Utils.getEtherBalance(allocationAddress2),
    //         allocationAddress3Balance = Utils.getEtherBalance(allocationAddress3);
    //
    //     await token.addMinter(phases.address);
    //
    //     await phases.setNodeAllocation(allocation.address)
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("39590").valueOf()))
    //
    //     let collectedEthers = await phases.getBalanceContract()
    //     assert.equal(collectedEthers.valueOf(), "1000000000000000000", 'collectedEthers is not equal')
    //
    //     //1000000000000000000 * 100 / 3283559600000000 = 30454.7540419 | 30454.7540419 * 30 / 100| 39591.1802545
    //     let soldTokens = await phases.getTokens()
    //     assert.equal(soldTokens.valueOf(), "39590", 'soldTokens is not equal')
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("0").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("0").add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("0").add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("79180").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").add(allocationAddress3Balance))
    //
    // });
    //
    // it("create contract & buy tokens ico & check bonus for second period & check ethers & check get... functions", async function () {
    //     let phases = await nodePhases.new(
    //         token.address,
    //         new BigNumber(10).mul(precision),
    //         new BigNumber(3283559600000000),
    //         new BigNumber(750000).mul(precision),
    //         now - 3600 * 24 * 23,
    //         now - 3600 * 24 * 22,
    //         new BigNumber(1000000).mul(precision),
    //         new BigNumber(9800000).mul(precision),
    //         now - 3600 * 24 * 20,
    //         now + 3600 * 24 * 20
    //     )
    //
    //     let allocation = await nodeAllocation.new(
    //         bountyAddress,
    //         [allocationAddress1, allocationAddress2],
    //         [allocationAddress1, allocationAddress2, allocationAddress3],
    //         [new BigNumber(50000), new BigNumber(120000), new BigNumber(5000000).mul(precision), new BigNumber(7000000).mul(precision)]
    //     )
    //
    //     let allocationAddress1Balance = Utils.getEtherBalance(allocationAddress1),
    //         allocationAddress2Balance = Utils.getEtherBalance(allocationAddress2),
    //         allocationAddress3Balance = Utils.getEtherBalance(allocationAddress3);
    //
    //     await token.addMinter(phases.address);
    //
    //     await phases.setNodeAllocation(allocation.address)
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("36544").valueOf()))
    //     //1000000000000000000 * 100 / 3283559600000000 = 30454.7540419 | 30454.7540419 * 20 / 100 | 36545.7048503
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("0").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("0").add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("0").add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("73088").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("109632").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("146176").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").mul(2).add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").mul(2).add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").mul(2).add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000"})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("182720").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").mul(2).add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").mul(2).add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").mul(2).add(allocationAddress3Balance))
    //
    //     await phases.sendTransaction({value: "1000000000000000000", from: accounts[1]})
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[1], new BigNumber("36544").valueOf()))
    //
    //     await Utils.checkEtherBalance(allocationAddress1, new BigNumber("60000000000000000").mul(2).add(allocationAddress1Balance))
    //     await Utils.checkEtherBalance(allocationAddress2, new BigNumber("940000000000000000").mul(2).add(allocationAddress2Balance))
    //     await Utils.checkEtherBalance(allocationAddress3, new BigNumber("1000000000000000000").mul(2).add(allocationAddress3Balance))
    //
    //     let investorsCount = await phases.getAllInvestors()
    //     assert.equal(investorsCount.valueOf(), "2", 'investorsCount is not equal')
    //
    //     let getTokens = await phases.getTokens()
    //     assert.equal(getTokens.valueOf(), "219264", 'getTokens is not equal')
    //
    //     let soldTokens = await phases.getSoldToken()
    //     assert.equal(soldTokens.valueOf(), "219264", 'getSoldToken is not equal')
    //
    //     let balanceContract = await phases.getBalanceContract()
    //     assert.equal(balanceContract.valueOf(), "6000000000000000000", 'balanceContract is not equal')
    // });
    //
    // it("create contract & check SendTo... functions, setCurrentRate", async function () {
    //     let phases = await nodePhases.new(
    //         token.address,
    //         new BigNumber(10).mul(precision),
    //         new BigNumber(3283559600000000),
    //         new BigNumber(750000).mul(precision),
    //         now - 3600 * 24 * 1,
    //         now + 3600 * 24 * 1,
    //         new BigNumber(1000000).mul(precision),
    //         new BigNumber(9800000).mul(precision),
    //         now + 3600 * 24 * 2,
    //         now + 3600 * 24 * 10
    //     )
    //
    //     let allocation = await nodeAllocation.new(
    //         bountyAddress,
    //         [allocationAddress1, allocationAddress2],
    //         [allocationAddress1, allocationAddress2, allocationAddress3],
    //         [new BigNumber(1000000).mul(precision), new BigNumber(3000000).mul(precision), new BigNumber(5000000).mul(precision), new BigNumber(7000000).mul(precision)]
    //     )
    //
    //     await token.addMinter(phases.address);
    //
    //     await phases.setNodeAllocation(allocation.address)
    //
    //     await phases.sendToAddress(accounts[1], 10000)
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[1], new BigNumber("15000").valueOf()))
    //
    //     await phases.sendToAddressWithTime(accounts[2], 10000, now + 3600 * 24 * 3)
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[2], new BigNumber("13000").valueOf()))
    //
    //     await phases.sendToAddressWithBonus(accounts[3], 10000, 18000)
    //         .then(() => Utils.receiptShouldSucceed)
    //         .then(() => Utils.balanceShouldEqualTo(token, accounts[3], new BigNumber("28000").valueOf()))
    //
    //     await phases.setCurrentRate(new BigNumber(3283559600000028))
    //
    //     await Utils.getPhase(phases, 0)
    //         .then((phase) => Utils.checkPhase(
    //             phase,
    //             new BigNumber(3283559600000028),
    //             new BigNumber(10).mul(precision),
    //             0,
    //             new BigNumber(750000).mul(precision),
    //             now - 3600 * 24 * 1,
    //             now + 3600 * 24 * 1,
    //             false
    //         ))
    //
    //     await Utils.getPhase(phases, 1)
    //         .then((phase) => Utils.checkPhase(
    //             phase,
    //             new BigNumber(3283559600000028),
    //             new BigNumber(10).mul(precision),
    //             new BigNumber(1000000).mul(precision),
    //             new BigNumber(9800000).mul(precision),
    //             now + 3600 * 24 * 2,
    //             now + 3600 * 24 * 10,
    //             false
    //         ))
    //
    //     await phases.setPhase(
    //         0,
    //         now - 3600 * 24 * 20,
    //         now - 3600 * 24 * 10,
    //         new BigNumber(3283559600000000),
    //         new BigNumber(0),
    //         new BigNumber(750001).mul(precision),
    //     )
    //         .then(Utils.receiptShouldSucceed)
    //
    //     await Utils.getPhase(phases, 0)
    //         .then((phase) => Utils.checkPhase(
    //             phase,
    //             new BigNumber(3283559600000000),
    //             new BigNumber(10).mul(precision),
    //             0,
    //             new BigNumber(750001).mul(precision),
    //             now - 3600 * 24 * 20,
    //             now - 3600 * 24 * 10,
    //             false
    //         ))
    //
    //     await phases.setNode(token.address)
    //
    // });

    it("create contract & check isSucceed, isFinished", async function () {
        let phases = await nodePhases.new(
            token.address,
            new BigNumber(10).mul(precision),
            new BigNumber(3283559600000000),
            new BigNumber(750000).mul(precision),
            now - 3600 * 24 * 23,
            now - 3600 * 24 * 22,
            new BigNumber(1000000).mul(precision),
            new BigNumber(9800000).mul(precision),
            now - 3600 * 24 * 20,
            now + 5
        )

        let allocation = await nodeAllocation.new(
            bountyAddress,
            [allocationAddress1, allocationAddress2],
            [allocationAddress1, allocationAddress2, allocationAddress3],
            [new BigNumber(50000).mul(precision), new BigNumber(120000).mul(precision), new BigNumber(5000000).mul(precision), new BigNumber(7000000).mul(precision)]
        )

        let allocationAddress1Balance = Utils.getEtherBalance(allocationAddress1),
            allocationAddress2Balance = Utils.getEtherBalance(allocationAddress2),
            allocationAddress3Balance = Utils.getEtherBalance(allocationAddress3),
            account1Balance = Utils.getEtherBalance(accounts[1]);

        await token.addMinter(phases.address);

        await phases.setNodeAllocation(allocation.address)

        await phases.sendTransaction({value: "1000000000000000000", from: accounts[1]})
            .then(() => Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[1], new BigNumber("36544").valueOf()))
        //1000000000000000000 * 100 / 3283559600000000 = 30454.7540419 | 30454.7540419 * 20 / 100 | 36545.7048503

        console.log('account1Balance before transaction', account1Balance.valueOf());
        console.log('account1Balance after transaction0', Utils.getEtherBalance(accounts[1]).valueOf());

        let isSucceed = await phases.isSucceed.call(0)
        assert.equal(isSucceed.valueOf(), true, 'isSucceed is not equal')

        let isFinished = await phases.isFinished.call(0)
        assert.equal(isFinished.valueOf(), true, 'isFinished is not equal')

        isSucceed = await phases.isSucceed.call(1)
        assert.equal(isSucceed.valueOf(), false, 'isSucceed is not equal')

        isFinished = await phases.isFinished.call(1)
        assert.equal(isFinished.valueOf(), false, 'isFinished is not equal')

        await phases.setPhase(
            1,
            now - 3600 * 24 * 20,
            now + 5,
            new BigNumber(3283559600000000),
            new BigNumber(300).mul(precision),
            new BigNumber(9800000).mul(precision),
        )
            .then(Utils.receiptShouldSucceed)

        isSucceed = await phases.isSucceed.call(1)
        assert.equal(isSucceed.valueOf(), false, 'isSucceed is not equal')

        isFinished = await phases.isFinished.call(1)
        assert.equal(isFinished.valueOf(), false, 'isFinished is not equal')

        await phases.setPhase(
            1,
            now - 3600 * 24 * 20,
            now - 5,
            new BigNumber(3283559600000000),
            new BigNumber(20000),
            new BigNumber(9800000).mul(precision),
        )
            .then(Utils.receiptShouldSucceed)

        isSucceed = await phases.isSucceed.call(1)
        assert.equal(isSucceed.valueOf(), true, 'isSucceed is not equal')

        isFinished = await phases.isFinished.call(1)
        assert.equal(isFinished.valueOf(), true, 'isFinished is not equal')

        await Utils.balanceShouldEqualTo(token, bountyAddress, new BigNumber("200000").valueOf())

        // await Utils.checkEtherBalance(allocationAddress1, new BigNumber("30000000000000000").add(allocationAddress1Balance))
        // await Utils.checkEtherBalance(allocationAddress2, new BigNumber("470000000000000000").add(allocationAddress2Balance))
        // await Utils.checkEtherBalance(allocationAddress3, new BigNumber("500000000000000000").add(allocationAddress3Balance))


        // let isRefunded = await phases.refund.call(1, {from: accounts[1]})
        // assert.equal(isRefunded.valueOf(), true, 'isRefunded is not equal')

        //
    });


});