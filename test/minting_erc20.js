var MintinERC20 = artifacts.require("./MintingERC20.sol");

let Utils = require("./utils");

let BigNumber = require('bignumber.js');
let precision = new BigNumber(1000000000000000000);

contract('MintinERC20', function (accounts) {
    let token;

    beforeEach(async function () {
        token = await MintinERC20.new(
            0, //uint256 _initialSupply,
            new BigNumber(100).mul(precision), //uint256 _maxSupply,
            'Minting', //string _tokenName,
            18,//uint8 _decimals,
            'MNT', // string _symbol,
            false,// bool _transferAllSupplyToOwner,
            false, // bool _locked
        )
    });

    it('should start with a totalSupply of 0', async function () {
        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("0").valueOf(), "total supply is not equal")
    });

    it('should mint a given amount of tokens to a given address', async function () {
        await token.mint(accounts[0], 100)
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("100").valueOf(), "total supply is not equal")
    });

    it('should fail to mint for non minters', async function () {
        await token.mint(accounts[0], 100, {from: accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("0").valueOf()))
        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("0").valueOf(), "total supply is not equal")
    });

    it('should be able to add minters', async function () {
        await token.addMinter(accounts[1])
            .then(Utils.receiptShouldSucceed)
        await token.mint(accounts[0], 100, {from: accounts[1]})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
        let totalSupply = await token.totalSupply.call()
        assert.equal(totalSupply.valueOf(), new BigNumber("100").valueOf(), "total supply is not equal")
    });

    it('should fail when non minter tries to add new minter', async function () {
        await token.addMinter(accounts[1], {from: accounts[1]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
    });

    it('should fail when non minter tries to remove minter', async function () {
        await token.addMinter(accounts[1])
            .then(Utils.receiptShouldSucceed)
        await token.removeMinter(accounts[1], {from: accounts[2]})
            .then(Utils.receiptShouldFailed)
            .catch(Utils.catchReceiptShouldFailed)
        await token.mint(accounts[0], 100, {from: accounts[1]})
            .then(Utils.receiptShouldSucceed)
            .then(() => Utils.balanceShouldEqualTo(token, accounts[0], new BigNumber("100").valueOf()))
    });

});