var MintinERC20 = artifacts.require("./MintingERC20.sol");

let Utils = require("./utils");

let BigNumber = require('bignumber.js');
let precision = new BigNumber(1000000000000000000);

contract('MintinERC20', function (accounts) {
    let token;

    beforeEach(async function () {
        token = await MintinERC20.new(
            0, //uint256 _initialSupply,
            new BigNumber(1).mul(precision), //uint256 _maxSupply,
            'Minting', //string _tokenName,
            18,//uint8 _decimals,
            'MNT', // string _symbol,
            false,// bool _transferAllSupplyToOwner,
            false, // bool _locked
            {gasLimit: 20000000000})
    });

    it('should start with a totalSupply of 0', async function () {
        const data = token.contract.totalSupply.getData();
        const gasEstimate = web3.eth.estimateGas({to: token.address, data: data});
        let totalSupply= await token.totalSupply.call({gasLimit: gasEstimate})
        assert.equal(totalSupply.valueOf(), new BigNumber("0").valueOf(), "total supply is not equal")
    });


    it('should mint a given amount of tokens to a given address', async function () {
        const data = token.contract.mint.getData(accounts[0], 100);
        const gasEstimate = web3.eth.estimateGas({to: token.address, data: data});
        await token.mint(accounts[0], 100, {gasLimit: gasEstimate})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
        let totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("100").valueOf(), "total supply is not equal")
    });

    it('should fail to mint for non minters', async function () {
        const data = token.contract.mint.getData(accounts[0], 100);
        const gasEstimate = web3.eth.estimateGas({to: token.address, data: data});
        await token.mint(accounts[0], 100, {from: accounts[1], gasLimit: gasEstimate})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("0").valueOf()))
        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("0").valueOf(), "total supply is not equal")
    });

    it('should be able to add minters', async function () {
        await token.addMinter(accounts[1])
            .then(Utils.receiptShouldSucceed)
        const data = token.contract.mint.getData(accounts[0], 100);
        const gasEstimate = web3.eth.estimateGas({to: token.address, data: data});
        await token.mint(accounts[0], 100, {from: accounts[1], gasLimit: gasEstimate})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
        let totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("100").valueOf(), "total supply is not equal")
    });

    it('should be able to remove minters', async function () {
        await token.addMinter(accounts[1])
        await token.mint(accounts[0], 100, {from: accounts[1]})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
        await token.removeMinter(accounts[1])
        await token.mint(accounts[0], 100, {from: accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
        let totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("100").valueOf(), "total supply is not equal")
    });

    it('should fail when non minter tries to add new minter', async function () {
        await token.addMinter(accounts[1],{from:accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
    });

    it('should fail when tries to mint more then max', async function () {
        await token.addMinter(accounts[1],{from:accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
    });

    it('should not allow to mint over max limit', async function () {
        const data = token.contract.mint.getData(accounts[0], new BigNumber(0.9).mul(precision).valueOf());
        const gasEstimate = web3.eth.estimateGas({to: token.address, data: data});
        await token.mint(accounts[0],  new BigNumber(0.9).mul(precision),{gasLimit: gasEstimate})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber(0.9).mul(precision).valueOf()))
        let totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber(0.9).mul(precision).valueOf(), "total supply is not equal")
        await token.mint(accounts[0],  new BigNumber(0.5).mul(precision))
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber(0.9).mul(precision).valueOf()))
        totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber(0.9).mul(precision).valueOf(), "total supply is not equal")
    });

    it('testing zero tokens minting', async function () {
        await token.mint(accounts[0],  new BigNumber(0).mul(precision))
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber(0).mul(precision).valueOf()))
        let totalSupply= await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber(0).mul(precision).valueOf(), "total supply is not equal")
    });
});